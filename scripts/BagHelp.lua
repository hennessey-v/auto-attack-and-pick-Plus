-------------------------------------------------------------------------------------
-------   背包物品模块
-------------------------------------------------------------------------------------
local InventoryHelper = {}

local DorpItem = {} --丢弃的物品列表

function InventoryHelper:Init(fn)
  
end

local DorpItemShop = {
    trident = true,--刺耳三叉戟
    --book_gardening = true,--应用园艺学
    moonglassaxe = true,--月光玻璃斧
    oceanfishingbobber_malbatross = true,--邪天翁羽浮标
    gzresource_tunacan = true,--鱼罐头
    oceanfishinglure_hermit_drowsy = true,--麻醉鱼饵
    chum = true, --鱼食
    compostwrap = true,-- 金坷垃
    oceanfishinglure_hermit_snow = true, --雪天鱼饵
    oceanfishinglure_hermit_heavy = true, --重量级鱼饵
    oceanfishinglure_hermit_rain = true, --雨天鱼饵
    
    honeyham = true,--蜜汁火腿
    perogies = true,--波兰水饺
    baconeggs = true,--培根煎蛋
    kabobs = true,--肉串
    meatballs = true,--肉丸
    seeds = true,--种子
}

---判断是否手上有物品，不一定是有武器
function InventoryHelper:getHandItem()
  return ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
end

function InventoryHelper:getPantItem()
  return true --裤子的枚举不知道，默认true
end

--- 统计全身的空格子数
function InventoryHelper:countEmptySlot()
  local EmptyCount = 0
  for i = 1, 15, 1 do
    if ThePlayer.replica.inventory:GetItemInSlot(i) == nil then
      EmptyCount = EmptyCount + 1
    end
  end
  local BackPack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
  if BackPack and BackPack.replica.container then
    local BackPackCtn = BackPack.replica.container
    for j = 1, BackPackCtn:GetNumSlots() do
      if BackPackCtn:GetItemInSlot(j) == nil then
        EmptyCount = EmptyCount + 1
      end
    end
  end
  return EmptyCount
end

--判断是否有空位
function InventoryHelper:hasEmptySlot()
  for i = 1, 15, 1 do
    if ThePlayer.replica.inventory:GetItemInSlot(i) == nil then
      return true
    end
  end
  local BackPack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
  if BackPack and BackPack.replica.container then
    local BackPackCtn = BackPack.replica.container
    for j = 1, BackPackCtn:GetNumSlots() do
      if BackPackCtn:GetItemInSlot(j) == nil then
        return true
      end
    end
  end
  return false
end

--- 物品栏取 1
---@param pfb_or_fn string | fun(item: Prefab): boolean
---@param is_pattern boolean | nil
function InventoryHelper:findItemInInv(pfb_or_fn, is_pattern)
  for i = 1, 15, 1 do
    local Item = ThePlayer.replica.inventory:GetItemInSlot(i)
    if
      Item
      and (
        type(pfb_or_fn) == "function" and pfb_or_fn(Item)
        or (is_pattern and string.match(Item.prefab, pfb_or_fn) ~= nil or Item.prefab == pfb_or_fn)
      )
    then
      return i, Item, ThePlayer.replica.inventory
    end
  end
  return nil, nil, nil
end

--- 背包取 1
---@param pfb_or_fn string | fun(item: Prefab): boolean
---@param is_pattern boolean | nil
function InventoryHelper:findItemInBackPack(pfb_or_fn, is_pattern)
  local BackPack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
  if BackPack and BackPack.replica.container then
    local BackPackBag = BackPack.replica.container
    for i = 1, BackPackBag:GetNumSlots() do
      local Item = BackPackBag:GetItemInSlot(i)
      if
        Item
        and (
          type(pfb_or_fn) == "function" and pfb_or_fn(Item)
          or (
            is_pattern and string.match(Item.prefab, pfb_or_fn) ~= nil or Item.prefab == pfb_or_fn
          )
        )
      then
        return i, Item, BackPack.replica.container
      end
    end
    return nil, nil, nil
  else
    return nil, nil, nil
  end
end


--- 物品栏和背包任取 1
---@param pfb_or_fn string | fun(item: Prefab): boolean
---@param is_pattern boolean | nil
function InventoryHelper:findItemInBothContainer(pfb_or_fn, is_pattern)
  local InvRes_1, InvRes_2, InvRes_3 = self:findItemInInv(pfb_or_fn, is_pattern)
  if InvRes_1 and InvRes_2 and InvRes_3 then
    return InvRes_1, InvRes_2, InvRes_3
  else
    return self:findItemInBackPack(pfb_or_fn, is_pattern)
  end
end


--- 物品栏和背包获取此物品全部引用
---@param pfb_or_fn string | fun(item: Prefab): boolean
---@param is_pattern boolean | nil
function InventoryHelper:findAllItemInBothContainer(pfb_or_fn, is_pattern)
  ---@type Prefab[]
  local Ret = {}

  for i = 1, 15, 1 do
    local Item = ThePlayer.replica.inventory:GetItemInSlot(i)
    if
      Item
      and (
        type(pfb_or_fn) == "function" and pfb_or_fn(Item)
        or (is_pattern and string.match(Item.prefab, pfb_or_fn) ~= nil or Item.prefab == pfb_or_fn)
      )
    then
      table.insert(Ret, Item)
    end
  end

  local BackPack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
  if BackPack and BackPack.replica.container then
    local BackPackBag = BackPack.replica.container
    for i = 1, BackPackBag:GetNumSlots() do
      local Item = BackPackBag:GetItemInSlot(i)
      if
        Item
        and (
          type(pfb_or_fn) == "function" and pfb_or_fn(Item)
          or (
            is_pattern and string.match(Item.prefab, pfb_or_fn) ~= nil or Item.prefab == pfb_or_fn
          )
        )
      then
        table.insert(Ret, Item)
      end
    end
  end

  return Ret
end

local function isFinddDorpItem(Item)
    for k,v in pairs(DorpItem) do
        if Item.name == v then
          return true
        end
    end
    return false
end


---分解时 自动丢弃对应物品
function InventoryHelper:DecomposeDorp()

    self:IterateBothContainer(function(Item)
        if Item then
            if ThePlayer:HasTag("playerghost") or (ThePlayer.sg ~= nil and ThePlayer.sg:HasStateTag("attack")) then
              Sleep(0.5)
            elseif Item.prefab == "gzresource_magicliquid" then
              if isFinddDorpItem(Item) then
                ThePlayer.replica.inventory:DropItemFromInvTile(Item)
                Sleep(0.2)
              end
            end
        end
    end)
end


--购物时 自动丢弃对应物品
function InventoryHelper:DecomposeDorpShop()

    self:IterateBothContainer(function(Item)
        if Item then
            if ThePlayer:HasTag("playerghost") or (ThePlayer.sg ~= nil and ThePlayer.sg:HasStateTag("attack")) then
              Sleep(0.5)
            end
            for k,v in pairs(DorpItemShop) do
                if v and Item.prefab == k then
                    ThePlayer.replica.inventory:DropItemFromInvTile(Item)
                    print("丢弃  ",Item.prefab)
                    Sleep(0.5)
                end
            end
        end
    end)
end


----遍历搜索

---@param ctn ContainerReplica
---@param fn fun(item: Prefab | nil, i: integer, ctn: ContainerReplica): boolean
---@return boolean is_skipped
function InventoryHelper:iterateContainer(ctn, fn)
  for i = 1, ctn:GetNumSlots() do
    local Skip = fn(ctn:GetItemInSlot(i), i, ctn)
    if Skip == true then
      return Skip
    end
  end
  return false
end

---@param fn fun(item: Prefab | nil, i: integer, ctn: ContainerReplica): boolean
---@return boolean is_skipped
function InventoryHelper:IterateInv(fn)
  return self:iterateContainer(ThePlayer.replica.inventory, fn)
end

---@param fn fun(item: Prefab | nil, i: integer, ctn: ContainerReplica): boolean
---@return boolean is_skipped
function InventoryHelper:IterateBackPack(fn)
  local Backpack = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BACK)

  if Backpack and Backpack.replica.container then
    return self:iterateContainer(Backpack.replica.container, fn)
  end
end

---@param fn fun(item: Prefab | nil, i: integer, ctn: ContainerReplica): boolean
function InventoryHelper:IterateBothContainer(fn)
  local InvSkipped = self:IterateInv(fn)

  if not InvSkipped then
    self:IterateBackPack(fn)
  end
end

return InventoryHelper
