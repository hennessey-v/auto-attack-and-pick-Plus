local Aikong = require("QAI-V2")
local BagHelp = require("BagHelp")
local DebugHelp = require("DebugHelp")
local move = require("util/move")

local function playersay(str)
  if ThePlayer.components.talker then
    local success, result =
      pcall(
      function()
        ThePlayer.components.talker:Say(str)
      end
    )

    if not success then
      print("发生错误:", result)
    end
  end
end

function hasHud() --没有界面和没有玩家对象不执行
  local ActiveScreen = TheFrontEnd:GetActiveScreen()
  local Name = ActiveScreen and ActiveScreen.name or ""
  return Name:find("HUD") ~= nil
end

-- 下面这个函数用来判断是否需要响应键盘按下的事件，排除非游戏界面、聊天界面和输入界面
local function IsDefaultScreen()
  local active_screen = TheFrontEnd:GetActiveScreen()
  local screen = active_screen and active_screen.name or ""
  return screen:find("HUD") ~= nil and ThePlayer ~= nil and not GLOBAL.ThePlayer.HUD:IsChatInputScreenOpen() and
    not GLOBAL.ThePlayer.HUD.writeablescreen
end

---
--- Mod Config todo
---

local PickKey = GetModConfigData("PickKey") == "close" and -1 or GLOBAL[GetModConfigData("PickKey")] --default
local AttackKey = GetModConfigData("AttackKey") == "close" and -1 or GLOBAL[GetModConfigData("AttackKey")] --default
local PickFirstConfig = GetModConfigData("PickFirst") --default false
local isPickResources = GetModConfigData("PickResources") --default true
local isPickSeeds = GetModConfigData("PickSeeds") --default true
local UsedRange = GetModConfigData("UsedRange") --default true

---初始化函数放在最前面
-- BagHelp:Init(GetModConfigData);

local TheModConfig = {} --todo

local TheThreads = {
  PickKey = nil,
  AttackKey = nil,
  PantSkill = nil,
  BodySkill = nil,
  HatSkill = nil,
  AutoShop = nil,
  Collect = nil,
  -- Mutex
  ---@type string[][]
  MutexThreadGroup = {
    {
      "PickKey",
      "AttackKey",
      "PantSkill",
      "BodySkill",
      "HatSkill",
      "AutoShop",
      "Collect"
    }
  }
}

local function generateItemIndex(ItemKind, Extra_fun)
  return function(t, k)
    if Extra_fun ~= nil and Extra_fun(k) then
      return Extra_fun(k).value
    end
    if ItemKind == "Equip" then
      local Name = k or ""
      return Name:find("gzequ_") ~= nil and not Name:find("gzequ_gardentool") and --不是锄头
        not Name:find("gzequ_minetool") --不是斧头
    end

    if ItemKind == "Seeds" then
      local Name = k or ""
      return Name:find("_seeds") ~= nil
    end
  end
end

--- 捡资源列表
local PickingResourcesPrefabs = {
  --要捡的东西的列表
  meat = true, --大肉
  gears = true, --齿轮
  steelwool = true, --钢丝棉
  lightninggoathorn = true, --伏特羊角
  pigskin = true, --猪皮
  livinglog = true, --活木
  cave_banana = true, --香蕉
  silk = true, --蜘蛛丝
  monstermeat = true, --怪物肉
  smallmeat = true, --小肉
  spidereggsack = true, --蜘蛛卵
  spidergland = true, --蜘蛛卵
  manrabbit_tail = true, --兔绒
  trunk_summer = true, --象鼻
  trunk_winter = true, --冬天象鼻
  poop = true, --粪肥
  nightmarefuel = true --噩梦燃料
}

local PickingSeedsPrefabs = {}

setmetatable(
  PickingSeedsPrefabs,
  {
    __index = generateItemIndex("Seeds")
  }
)

--移动到背包的东西
local MoveToBackPrefabs = {
  monstermeat = true, --怪物肉
  bonestew = true, --炖肉汤
  cave_banana = true --香蕉
}

-- 战斗更为优先
local LockBattleSuperior = false
local IsOnBattle = false
local IsOnPick = false

local function releaseOnBattle()
  ThePlayer:StartThread(
    function()
      Sleep(1)
      if IsOnBattle then
        IsOnBattle = false
      end
    end
  )
end

local function releaseOnPick()
  IsOnPick = false
end

---@param x number
---@param y number
---@param z number
---@param range number
---@param fn fun(v: Prefab): boolean | nil
---@param musttags string[] | nil
---@param canttags string[] | nil
---@param mustoneoftags string[] | nil
---@param prefab string | nil
function findAllEntities(x, y, z, range, fn, musttags, canttags, mustoneoftags, prefab)
  if x == nil or y == nil or z == nil then
    x, y, z = ThePlayer.Transform:GetWorldPosition()
  end

  local Ents = TheSim:FindEntities(x, y, z, range, musttags, canttags, mustoneoftags)
  ---@type Prefab[]
  local Aimed = {}

  for i, v in ipairs(Ents) do
    if v ~= ThePlayer and v.entity:IsVisible() and (fn == nil or fn(v)) and (prefab == nil or prefab == v.prefab) then
      table.insert(Aimed, v)
    end
  end
  return Aimed
end

--- 战斗寻敌
---@param player_pos Point
---@param allow_ocean boolean | nil
local function getHostile(player_pos, allow_ocean)
  local Dx, Dy, Dz

  if player_pos == nil then
    Dx, Dy, Dz = ThePlayer.Transform:GetWorldPosition()
  elseif player_pos ~= nil then
    Dx = player_pos.x
    Dy = player_pos.y
    Dz = player_pos.z
  end

  local TargetArray =
    findAllEntities(
    Dx,
    Dy,
    Dz,
    UsedRange,
    function(target)
      return target:IsValid() and not ThePlayer:HasTag("playerghost") and
        (allow_ocean or IsLandTile(TheWorld.Map:GetTileAtPoint(target.Transform:GetWorldPosition()))) and
        ThePlayer.replica.combat:CanTarget(target)
    end,
    {"_combat", "_health"},
    {"FX", "NOCLICK", "DECOR", "INLIMBO", "wall"},
    nil
  )

  table.sort(
    TargetArray,
    function(a, b)
      return ThePlayer:GetDistanceSqToPoint(a.Transform:GetWorldPosition()) <
        ThePlayer:GetDistanceSqToPoint(b.Transform:GetWorldPosition())
    end
  )

  local Target = TargetArray[1]
  --[[ 
    怪物优先级 todo maybe
  --]]
  return Target, TargetArray
end

--- 寻找拾取物
-- TODO: 拾取物优先级
---@param player_pos Point
---@param only_full_stack boolean | nil
---@param extra_sorter fun(a: Prefab, b: Prefab): boolean | nil
---@param ignore_global_setting_filter fun(target: Prefab): boolean | nil
local function getPickings(player_pos, only_full_stack, extra_sorter, ignore_global_setting_filter)
  local Dx, Dy, Dz
  if player_pos ~= nil then
    Dx = player_pos.x
    Dy = player_pos.y
    Dz = player_pos.z
  else
    Dx, Dy, Dz = ThePlayer.Transform:GetWorldPosition()
  end

  local PickableArray =
    findAllEntities(
    Dx,
    Dy,
    Dz,
    UsedRange,
    function(target)
      if
        (isPickResources and {not PickingResourcesPrefabs[target.prefab]} or {true})[1] and --三目运算符 都没找到
          (isPickSeeds and {not PickingSeedsPrefabs[target.prefab]} or {true})[1]
       then
        if ignore_global_setting_filter == nil or not ignore_global_setting_filter(target) then
          return false
        end
      end

      if IsOceanTile(TheWorld.Map:GetTileAtPoint(target.Transform:GetWorldPosition())) then
        return false
      end

      local LA = ThePlayer.components.playeractionpicker:DoGetMouseActions(target:GetPosition(), target)
      return LA and LA.action.code == ACTIONS.PICKUP.code and
        (not only_full_stack or not target.replica.stackable or
          target.replica.stackable:MaxSize() == target.replica.stackable:StackSize())
    end,
    {"_inventoryitem"},
    {"INLIMBO", "noauradamage"}
  )

  table.sort(
    PickableArray,
    extra_sorter and extra_sorter or
      function(a, b)
        return ThePlayer:GetDistanceSqToPoint(a.Transform:GetWorldPosition()) <
          ThePlayer:GetDistanceSqToPoint(b.Transform:GetWorldPosition())
      end
  )

  return PickableArray[1]
end

local function doPick(item)
  local Pos = item:GetPosition()
  pcall(
    function()
      local LeftAction = ThePlayer.components.playeractionpicker:DoGetMouseActions(Pos, item)
      if LeftAction then
        local actionS = LeftAction:GetActionString() or ""
        if actionS ~= STRINGS.ACTIONS.REEL.CANCEL then
          ThePlayer.components.playercontroller:DoAction(LeftAction)
          SendRPCToServer(
            RPC.LeftClick,
            LeftAction.action.code,
            Pos.x,
            Pos.z,
            item,
            false,
            ThePlayer.components.playercontroller:EncodeControlMods(),
            false,
            LeftAction.action.mod_name
          )
        end
      end
    end
  )
end

local ReadyStates = {
  isReadyToFight = function()
    return not ThePlayer:HasTag("playerghost") and not ThePlayer:HasTag("giving")
  end,
  isReadyToPick = function()
    return ThePlayer.sg ~= nil and not ThePlayer.sg:HasStateTag("attack") and not ThePlayer.sg:HasStateTag("moving") and
      not ThePlayer:HasTag("playerghost") and
      not ThePlayer:HasTag("giving") and
      BagHelp:hasEmptySlot()
  end,
  isReadyToDecompose = function()
    return ThePlayer.sg ~= nil and not ThePlayer:HasTag("playerghost") and not ThePlayer.sg:HasStateTag("attack")
  end,
  isReadyTobBuyStick = function()
    return not ThePlayer:HasTag("playerghost") and BagHelp:hasEmptySlot()
    --and ThePlayer.replica.health:GetCurrent() ~= 50 --这个服务器无效，死亡时的血量是50
    --and ThePlayer.replica.health:GetCurrent() > 0 这个函数这这个服务器无效，都会是正数
    --and not ThePlayer.replica.health:IsDead() 这个函数这这个服务器无效
  end,
  isReadyToSell = function()
    return ThePlayer.sg ~= nil and not ThePlayer.sg:HasStateTag("attack") and not ThePlayer:HasTag("playerghost")
  end
}

----
---- 自动拾取
----
local function autoFunc_Pick()
  playersay("开始自动拾取")

  local PlayerPosition = ThePlayer:GetPosition()
  local AI = Aikong(ThePlayer)

  while true do
    if LockBattleSuperior then
      Sleep(0.5)
    end
    local Pickings
    if not LockBattleSuperior and ReadyStates.isReadyToPick() then
      Pickings = getPickings(PlayerPosition)
      if Pickings ~= nil then
        IsOnPick = true
        doPick(Pickings)
        Sleep(0.07)
      end
    end
    if Pickings == nil then
      releaseOnPick()
      --if TheThreads.AttackKey == nil then
      --AI:GoTo(PlayerPosition)
      --end

      -- 移动种子等到背包
      ThePlayer.replica.inventory:MoveItemFromAllOfSlot(
        BagHelp:findItemInInv(
          function(item)
            return PickingSeedsPrefabs[item.prefab] == true or MoveToBackPrefabs[item.prefab] == true
          end
        ),
        ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
      )
    end
    Sleep(0.07)
  end
end

function isPickFirst(Target, Item) --判断是否优先拾取
  if Target == nil or Item == nil then
    return false
  end
  local disTarget = ThePlayer:GetDistanceSqToPoint(Target.Transform:GetWorldPosition())
  local disItem = ThePlayer:GetDistanceSqToPoint(Item.Transform:GetWorldPosition())
  if disTarget > 15 and disItem < 8 then
    return true
  end
  return false
end

----
---- 自动挂机
----
local function autoFunc_fight()
  playersay("开始自动战斗")

  local PlayerPosition = ThePlayer:GetPosition()
  local AI = Aikong(ThePlayer)

  while true do
    LockBattleSuperior = true

    local Target = getHostile(PlayerPosition, 45)
    if Target ~= nil and ReadyStates.isReadyToFight() then
      if not IsOnBattle then
        IsOnBattle = true
      end

      local isFirst = false
      if PickFirstConfig and TheThreads.PickKey ~= nil then --如果开了拾取 则距离很近的时候优先拾取
        local Pickings = getPickings()
        if isPickFirst(Target, Pickings) then
          IsOnPick = true
          isFirst = true
          doPick(Pickings)
        --Sleep(0.1)
        end
      end
      if not isFirst then
        AI:GJ(Target)
        Sleep(0.2)
      else
        Sleep(0.3)
      end
    else
      releaseOnBattle()
      LockBattleSuperior = false
      if
        (not PickFirstConfig or TheThreads.PickKey == nil) and ThePlayer.sg ~= nil and
          not ThePlayer.sg:HasStateTag("moving") and
          not ThePlayer.sg:HasStateTag("doing") and
          not ThePlayer:HasTag("giving")
       then --在移动状态和拾取状态就不会返回原地继续执行捡东西操作
        AI:GoTo(PlayerPosition)
      end
      Sleep(0.5)
    end
  end
end

----
---- 自动拾取装备PickKey
----

----
---- 自动战斗挂机AttackKey
----

-- 开启自动攻击
function auto:OnAttack()
  if ThePlayer == nil or not hasHud() then --没有界面和没有玩家对象不执行
    return
  end
  if BagHelp:getHandItem() == nil then
    playersay("手上没有装备武器哦")
    return
  end
  TheThreads.AttackKey = ThePlayer:StartThread(autoFunc_fight)
end

-- 关闭自动攻击
function auto:OffAttack()
  playersay("停止自动战斗")
  KillThread(TheThreads.AttackKey)
  TheThreads.AttackKey = nil
  LockBattleSuperior = false
end

-- 开启自动拾取
function auto:OnPick()
  if ThePlayer == nil or not hasHud() then
    return
  end
  TheThreads.PickKey = ThePlayer:StartThread(autoFunc_Pick)
end

-- 关闭自动拾取
function auto:OffPick()
  playersay("停止拾取")
  KillThread(TheThreads.PickKey)
  TheThreads.PickKey = nil
  releaseOnPick()
end

return auto
