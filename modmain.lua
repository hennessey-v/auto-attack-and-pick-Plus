--头文件

GLOBAL.setmetatable(env, {
  __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
  end,
})

local Aikong = require("QAI-V2")
local BagHelp = require("BagHelp")
local DebugHelp = require("DebugHelp")
local move = require ("util/move")

local MOD_EQUIPMENT_CONTROL = {}
MOD_EQUIPMENT_CONTROL.MODNAME = modname
GLOBAL.MOD_EQUIPMENT_CONTROL = MOD_EQUIPMENT_CONTROL

local function playersay(str)
  if ThePlayer.components.talker then
      local success, result = pcall(function()
          ThePlayer.components.talker:Say(str)
      end)
      
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
  return screen:find("HUD") ~= nil and ThePlayer ~= nil and
          not GLOBAL.ThePlayer.HUD:IsChatInputScreenOpen() and not GLOBAL.ThePlayer.HUD.writeablescreen
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
local key = GetModConfigData("key_toggle") and GLOBAL[GetModConfigData("key_toggle")] or GLOBAL['KEY_H']


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
      "Collect",
    },
  },
}

local function generateItemIndex(ItemKind, Extra_fun)
  return function(t, k)
    if Extra_fun ~= nil and Extra_fun(k) then
      return Extra_fun(k).value
    end
    if ItemKind == "Equip" then
        local Name = k or ""
        return Name:find("gzequ_") ~= nil 
            and not Name:find("gzequ_gardentool") --不是锄头
            and not Name:find("gzequ_minetool") --不是斧头
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
    steelwool = true,--钢丝棉
    lightninggoathorn = true,--伏特羊角
    pigskin = true,--猪皮
    livinglog = true,--活木
    cave_banana = true,--香蕉
    silk = true,--蜘蛛丝
    monstermeat = true, --怪物肉
    smallmeat = true, --小肉
    spidereggsack = true, --蜘蛛卵
    spidergland = true, --蜘蛛卵
    manrabbit_tail = true, --兔绒
    trunk_summer = true, --象鼻
    trunk_winter = true, --冬天象鼻
    poop = true, --粪肥
    nightmarefuel = true, --噩梦燃料
}


local PickingSeedsPrefabs = {
    --要捡的种子列表
    --seeds = true,--种子
    --potato_seeds = true, --土豆
    --onion_seeds = true, --土豆
}

setmetatable(PickingSeedsPrefabs, {
  __index = generateItemIndex("Seeds")
  
})

--移动到背包的东西
local MoveToBackPrefabs = {
    monstermeat = true, --怪物肉
    bonestew = true, --炖肉汤
    cave_banana = true, --香蕉
}


-- 战斗更为优先
local LockBattleSuperior = false
local IsOnBattle = false
local IsOnPick = false

local function releaseOnBattle()
  ThePlayer:StartThread(function()
    Sleep(1)
    if IsOnBattle then
      IsOnBattle = false
    end
  end)
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
    if
      v ~= ThePlayer
      and v.entity:IsVisible()
      and (fn == nil or fn(v))
      and (prefab == nil or prefab == v.prefab)
    then
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

  local TargetArray = findAllEntities(Dx, Dy, Dz, UsedRange, function(target)
    return target:IsValid()
      and not ThePlayer:HasTag("playerghost")
      and (allow_ocean or IsLandTile(TheWorld.Map:GetTileAtPoint(target.Transform:GetWorldPosition())))
      and ThePlayer.replica.combat:CanTarget(target)
  end, { "_combat", "_health" }, { "FX", "NOCLICK", "DECOR", "INLIMBO", "wall" }, nil)

  table.sort(TargetArray, function(a, b)
    return ThePlayer:GetDistanceSqToPoint(a.Transform:GetWorldPosition())
      < ThePlayer:GetDistanceSqToPoint(b.Transform:GetWorldPosition())
  end)

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
local function getPickings(
  player_pos,
  only_full_stack,
  extra_sorter,
  ignore_global_setting_filter
)

  local Dx, Dy, Dz
  if player_pos ~= nil then
    Dx = player_pos.x
    Dy = player_pos.y
    Dz = player_pos.z
  else
    Dx, Dy, Dz = ThePlayer.Transform:GetWorldPosition()
  end

  local PickableArray = findAllEntities(Dx, Dy, Dz, UsedRange, function(target)

    if (isPickResources and {not PickingResourcesPrefabs[target.prefab]} or {true})[1] --三目运算符 都没找到
    and (isPickSeeds and {not PickingSeedsPrefabs[target.prefab]} or {true})[1] then
        if ignore_global_setting_filter == nil or not ignore_global_setting_filter(target) then
            return false
        end
    end

    if IsOceanTile(TheWorld.Map:GetTileAtPoint(target.Transform:GetWorldPosition())) then
      return false
    end

    local LA = ThePlayer.components.playeractionpicker:DoGetMouseActions(target:GetPosition(), target)
    return LA
      and LA.action.code == ACTIONS.PICKUP.code
      and (not only_full_stack or not target.replica.stackable or target.replica.stackable:MaxSize() == target.replica.stackable:StackSize())
  end, { "_inventoryitem" }, { "INLIMBO", "noauradamage" })

  table.sort(PickableArray, extra_sorter and extra_sorter or function(a, b)
    return ThePlayer:GetDistanceSqToPoint(a.Transform:GetWorldPosition())
      < ThePlayer:GetDistanceSqToPoint(b.Transform:GetWorldPosition())
  end)

  return PickableArray[1]
end


local function doPick(item)
  local Pos = item:GetPosition()
  pcall(function()
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
  end)
end

local ReadyStates = {
  isReadyToFight = function()
    return not ThePlayer:HasTag("playerghost") 
           and not ThePlayer:HasTag("giving")
  end,
  isReadyToPick = function()
    return 
    ThePlayer.sg ~= nil 
    and not ThePlayer.sg:HasStateTag("attack")
    and not ThePlayer.sg:HasStateTag("moving")
    and not ThePlayer:HasTag("playerghost") 
    and not ThePlayer:HasTag("giving") 
    and BagHelp:hasEmptySlot() 
    
  end,
  isReadyToDecompose = function()
    return ThePlayer.sg ~= nil 
           and not ThePlayer:HasTag("playerghost") 
           and not ThePlayer.sg:HasStateTag("attack") 
  end,
  isReadyTobBuyStick = function()
    return not ThePlayer:HasTag("playerghost") 
           and BagHelp:hasEmptySlot()
           --and ThePlayer.replica.health:GetCurrent() ~= 50 --这个服务器无效，死亡时的血量是50
           --and ThePlayer.replica.health:GetCurrent() > 0 这个函数这这个服务器无效，都会是正数
           --and not ThePlayer.replica.health:IsDead() 这个函数这这个服务器无效
  end,
  
  isReadyToSell = function()
    return ThePlayer.sg ~= nil 
           and not ThePlayer.sg:HasStateTag("attack")
           and not ThePlayer:HasTag("playerghost")
    end,
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
    if not LockBattleSuperior 
       and ReadyStates.isReadyToPick() 
       then
          Pickings = getPickings(PlayerPosition)
          if Pickings ~=  nil then
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
        BagHelp:findItemInInv(function(item)
          return PickingSeedsPrefabs[item.prefab] == true or MoveToBackPrefabs[item.prefab] == true
        end),
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
      if (not PickFirstConfig or TheThreads.PickKey == nil)
         and ThePlayer.sg ~= nil 
         and not ThePlayer.sg:HasStateTag("moving") 
         and not ThePlayer.sg:HasStateTag("doing")
         and not ThePlayer:HasTag("giving") then --在移动状态和拾取状态就不会返回原地继续执行捡东西操作
         AI:GoTo(PlayerPosition)
      end
      Sleep(0.5)
    end
  end
end

----
---- 自动拾取装备
----
TheInput:AddKeyDownHandler(PickKey, function()
  if ThePlayer == nil or not hasHud() then
    return
  end

  if TheThreads.PickKey then
    playersay("停止拾取")
    KillThread(TheThreads.PickKey)
    TheThreads.PickKey = nil
    releaseOnPick();
  else
    TheThreads.PickKey = ThePlayer:StartThread(autoFunc_Pick)
  end
end)




----
---- 自动战斗挂机
----
TheInput:AddKeyDownHandler(AttackKey, function()
  if ThePlayer == nil or not hasHud() then --没有界面和没有玩家对象不执行
    return
  end

  if BagHelp:getHandItem() == nil then
  playersay("手上没有装备武器哦")
    return
  end

  if TheThreads.AttackKey then
    playersay("停止自动战斗")
    KillThread(TheThreads.AttackKey)
    TheThreads.AttackKey = nil
    LockBattleSuperior = false
  else
    TheThreads.AttackKey = ThePlayer:StartThread(autoFunc_fight)
  end
end)


local function getArgs(fun)
local args = {}
local hook = debug.gethook()

local argHook = function( ... )
    local info = debug.getinfo(3)
    if 'pcall' ~= info.name then return end

    for i = 1, math.huge do
        local name, value = debug.getlocal(2, i)
        if '(*temporary)' == name then
            debug.sethook(hook)
            error('')
            return
        end
        table.insert(args,name)
    end
end

debug.sethook(argHook, "c")
pcall(fun)

return args
end

-- local function MoveCharacter(inst)
--   print("随机位移")
--   local Dx, Dy, Dz = inst.Transform:GetWorldPosition()
--   local angle = math.random() * 2 * PI
--   local dx = Dx + math.cos(angle)
--   local dy = Dy + math.sin(angle)
--   inst.Transform:SetPosition(dx, dy, Dz) -- 保持原有的 z 坐标不变
-- end

------------------------------------------------------------

--[[ 这是个测试功能函数 打开无效开发的时候测试有无效果
TheInput:AddKeyDownHandler(KEY_J, function()
  if ThePlayer == nil or not hasHud() then --没有界面和没有玩家对象不执行
    return
  end
  --重写TheNet的SendModRPCToServer函数
    playersay("重写函数开始")
    print("重写函数开始")
    local mt = getmetatable(TheNet).__index
    local old_SendModRPCToServer = mt.SendModRPCToServer
    mt.SendModRPCToServer = 
    function(thenet, ...)
        old_SendModRPCToServer(thenet, ...)
        print("发送了一条")
        local args = {...}
        if type(args[1]) == "string" and args[1] == "fuck" then
            print("捕获了fuck")
            DebugHelp:showPrintInfo(...)
        end
    end
end)
--]]


--[[ 这是个测试功能函数 打开无效开发的时候测试有无效果
TheInput:AddKeyDownHandler(KEY_INSERT, function()
  if ThePlayer == nil or not hasHud() then --没有界面和没有玩家对象不执行
    return
  end
  --重写TheNet的SendModRPCToServer函数
    playersay("看看标签")
    print("看看标签")
    local myentity = ThePlayer.replica.inventory:GetActiveItem()
    if myentity then
        
        if(myentity.replica and myentity.replica.GetQuality) then 
        print(getArgs(myentity.replica.GetQuality))
        --DebugHelp:showPrintInfo(myentity)
        myentity.replica.GetQuality()
        end
    end
end)
--]]

-----------------------------------------------------------------------------------
-- Tech




-- 这个变量用于保存我们新建的对话框实例，可以通过这个变量显示和隐藏对话框
local controls;
-- AddClassPostConstruct是一个模组API，这个函数可以让我们对饥荒源代码中的类进行修改
-- 我们这里修改了widgets/controls这个类（即管理各种控件的类），在控件中插入我们的对话框
AddClassPostConstruct("widgets/controls", function(self)
    controls = self;
    -- 引入我们的对话框定义文件，注意这里的Tech与对话框定义的文件名对应
    local TechWidget = require ("widgets/Tech")
    if controls and controls.containerroot then
        -- 新建对话框类的实例
        controls.Tech = controls.containerroot:AddChild(TechWidget())
        -- 初始时不显示对话框，IsNoMuTechMenuShow用于对话框的显示状态
        controls.Tech.IsNoMuTechMenuShow = false;
        controls.Tech:Hide()
    end
end)

-- 添加key按键松开的响应函数
TheInput:AddKeyUpHandler(key, function()
    -- 判断是否需要处理
    if IsDefaultScreen() then
        -- print("按键按下")
        if controls and controls.Tech then
            -- 根据对话框当前的显示状态（即IsNoMuTechMenuShow），对对话框进行打开（Show）或关闭（Hide）
            if controls.Tech.IsNoMuTechMenuShow then
                controls.Tech:Hide()
                controls.Tech.IsNoMuTechMenuShow = false
            else
                controls.Tech:Show()
                controls.Tech.IsNoMuTechMenuShow = true
            end
        end
    end
end)


