local function count(c)
  return type(c) == "table"
      and c.replica
      and c.replica.stackable
      and c.replica.stackable:StackSize()
    or c and 0x1
    or nil
end

MYEQUIPSLOTS =
{
    HEAD = "head",
    BODY = "body",
}

local strfind = string.find

local function GetStackSize(item)
  return type(item) == "table"
      and item.replica
      and item.replica.stackable
      and item.replica.stackable:StackSize()
    or item and 1
    or nil
end

local QMAIXT = Class(function(self, inst)
  self.inst = inst
  self.Lo = self.inst.components.locomotor
  self.Ku = self.inst.replica.inventory
  self.Rc = self.inst.components.playercontroller
  self.Ac = self.inst.components.playeractionpicker
  self.Bc = self.inst.replica.builder
  self.Ca = self.inst.replica.combat
  self.Totbl = {}
  self.CaiDan = {}
  self.hangxian = 1
  for k, v in pairs(AllRecipes) do
    self.CaiDan[v.name] = v.rpc_id
  end
end)

QMAIXT.GJ = function(self, target)
  if
    target
    and target:IsValid()
    and (self.inst.sg == nil or not self.inst.sg:HasStateTag("abouttoattack"))
    and not self.Ca:CanHitTarget(target)
  then
    self:GoTodiren(target)
  end

  target = self.Ca and self.Rc:GetAttackTarget(true, target, target ~= nil)
  if target then
    if self.Lo == nil then
      self.Rc:RemoteAttackButton(target, true)
    elseif self.Lo ~= nil then
      local buffaction = BufferedAction(self.inst, target, ACTIONS.ATTACK)
      buffaction.preview_cb = function()
        self.Rc:RemoteAttackButton(target, true)
      end
      self.Lo:PreviewAction(buffaction, true)
    end
  end
  return self.Ca and self.Ca:CanHitTarget(target)
end

QMAIXT.RRR = function(self, pos)
  self.inst:EnableMovementPrediction(true)
  self.inst.components.locomotor:GoToPoint(pos, nil, nil)
  --print("+1")
  return self.inst:GetDistanceSqToPoint(pos:Get())
end

QMAIXT.GoTo = QMAIXT.RRR

QMAIXT.GoTodiren = function(self, target)
  self.inst:EnableMovementPrediction(true)
  self.inst.components.locomotor:GoToEntity(target, nil, nil)
  --print("+1")
  return self.inst:GetDistanceSqToPoint(target:GetPosition())
end

QMAIXT.LMBac = function(self, pos, target, ac)
  pos = pos or target and target:GetPosition() or nil
  if pos then
    if self.Lo == nil then
      self.Rc.remote_controls[CONTROL_PRIMARY] = 0
      SendRPCToServer(
        RPC.LeftClick,
        ac.action.code,
        pos.x,
        pos.z,
        target,
        false,
        nil,
        false,
        ac.action.mod_name
      )
    elseif self.Lo ~= nil then
      ac.preview_cb = function()
        self.Rc.remote_controls[CONTROL_PRIMARY] = 0
        SendRPCToServer(
          RPC.LeftClick,
          ac.action.code,
          pos.x,
          pos.z,
          target,
          false,
          nil,
          false,
          ac.action.mod_name
        )
      end
    end
    self.Rc:DoAction(ac)
  end
end

QMAIXT.RMBac = function(self, pos, target, ac)
  pos = pos or target and target:GetPosition() or nil
  if pos then
    local controlmods = self.Rc:EncodeControlMods()
    if self.Lo == nil then
      self.Rc.remote_controls[CONTROL_PRIMARY] = 0
      SendRPCToServer(
        RPC.RightClick,
        ac.action.code,
        pos.x,
        pos.z,
        target,
        false,
        nil,
        controlmods,
        nil,
        ac.action.mod_name
      )
    elseif self.Lo ~= nil then
      ac.preview_cb = function()
        self.Rc.remote_controls[CONTROL_PRIMARY] = 0
        SendRPCToServer(
          RPC.RightClick,
          ac.action.code,
          pos.x,
          pos.z,
          target,
          false,
          nil,
          controlmods,
          nil,
          ac.action.mod_name
        )
      end
    end
    self.Rc:DoAction(ac)
  end
end

QMAIXT.Rinv = function(self, target, ace, time)
  local dt = time and time > 0 and time or 0.1
  if target ~= nil and ace ~= nil then
    self.Rc:RemoteControllerUseItemOnSelfFromInvTile(ace, target)
  end
  Sleep(dt)
end

QMAIXT.Do = function(self, pos, target, ac, str, fn, time)
  local dt = time and time > 0 and time or 0.1
  local pt = pos and pos or target and target:GetPosition() or nil
  if pt then
    local LMB, RMB = self.Ac:DoGetMouseActions(pt, target)
    if
      LMB
      and (ac == nil or LMB.action == ac)
      and (str == nil or LMB:GetActionString() == str)
      and (fn == nil or fn(LMB))
    then
      self.LMBac(self, pt, target, LMB)
    elseif
      RMB
      and (ac == nil or RMB.action == ac)
      and (str == nil or RMB:GetActionString() == str)
      and (fn == nil or fn(RMB))
    then
      self.RMBac(self, pt, target, RMB)
    end
  end
  Sleep(dt)
end

QMAIXT.diaoluo = function(self, num, buer, yushe, biaoqian)
  if buer then
    while true do
      local wu = true
      for i = 1, self.Ku:GetNumSlots() do
        local a1 = self.Ku:GetItemInSlot(i)
        if
          a1
          and (yushe == nil or a1.prefab ~= yushe)
          and (biaoqian == nil or not a1:HasTag(biaoqian))
        then
          wu = false
          SendRPCToServer(RPC.DropItemFromInvTile, a1)
          break
        end
      end
      Sleep(0.1)
      if wu then
        break
      end
    end
  else
    local a1 = self.Ku:GetItemInSlot(num)
    SendRPCToServer(RPC.DropItemFromInvTile, a1)
  end
  Sleep(0.1)
end

QMAIXT.zhizuo = function(self, recipe)
  if self.Bc:CanBuild(recipe) then
    local rpc_id = self.CaiDan[recipe] or (AllRecipes[recipe] and AllRecipes[recipe].rpc_id)
    if rpc_id then
      SendRPCToServer(RPC.MakeRecipeFromMenu, rpc_id)
      Sleep(0.1)
      return true
    end
    Sleep(0.1)
    return false
  end
  Sleep(0.1)
  return false
end

QMAIXT.GoToT = function(self, fn, data, fw, time, ...)
  local dt = time and time > 0 and time or 0.1
  fw = fw or 1
  if data and type(data) == "table" and data[1] ~= nil then
    self.Totbl = data
    while true do
      if fn ~= nil and fn(self, self.inst, ...) then
        break
      elseif self.inst:GetDistanceSqToPoint(self.Totbl[1]:Get()) <= fw then
        table.remove(self.Totbl, self.Totbl[1])
        if self.Totbl[1] ~= nil then
          self.GoTo(self, self.Totbl[1])
        else
          break
        end
      else
        self.GoTo(self, self.Totbl[1])
      end
      Sleep(dt)
    end
  end
  Sleep(dt)
end

QMAIXT.tuoluo = function(self, item, buer)
  if item then
    SendRPCToServer(RPC.DropItemFromInvTile, item, buer)
  end
  Sleep(0.1)
end

QMAIXT.shouB = function(self, buer)
  self.Ku:DropItemFromInvTile(self.Ku:GetActiveItem(), buer)
end

QMAIXT.shouA = function(self, num)
  SendRPCToServer(RPC.TakeActiveItemFromAllOfSlot, num)
end

QMAIXT.shouC = function(self)
  if self.Ku:GetActiveItem() then
    local cao = nil
    for i = 1, self.Ku:GetNumSlots() do
      local a1 = self.Ku:GetItemInSlot(i)
      if a1 == nil then
        cao = i
        break
      end
    end
    self.Ku:ReturnActiveItem()
    return cao
  end
end

QMAIXT.suoyinA = function(self, yushe, biaoqian, zhengze, fn)
  for i = 1, self.Ku:GetNumSlots() do
    local a1 = self.Ku:GetItemInSlot(i)
    if
      a1
      and (yushe == nil or a1.prefab == yushe)
      and (biaoqian == nil or a1:HasTag(biaoqian))
      and (zhengze == nil or strfind(a1.prefab, zhengze) ~= nil)
      and (fn == nil or fn(a1))
    then
      return a1, i
    end
  end
end

QMAIXT.suoyinB = function(self, w, x, G, fn)
  local C = self.Ku:GetOverflowContainer()

  if C ~= nil then
    for i = 0x1, C:GetNumSlots() do
      local z = C:GetItemInSlot(i)
      if
        z
        and (w == nil or z["prefab"] == w)
        and (x == nil or z:HasTag(x))
        and (G == nil or strfind(z["prefab"], G) ~= nil)
        and (fn == nil or fn(z))
      then
        return z, i, C
      end
    end
  end
end

QMAIXT.suoyinC = function(self, yushe, biaoqian, zhengze, fn)
  local item = self.suoyinA(self, yushe, biaoqian, zhengze, fn)
  if item == nil then
    item = self.suoyinB(self, yushe, biaoqian, zhengze, fn)
  end
  return item
end

QMAIXT.suoyinD = function(self, yushe, biaoqian, bei)
  if bei and bei.replica and bei.replica.container ~= nil then
    local bao = bei.replica.container
    for i = 1, bao:GetNumSlots() do
      local a1 = bao:GetItemInSlot(i)
      if
        a1
        and (yushe == nil or a1.prefab == yushe)
        and (biaoqian == nil or a1:HasTag(biaoqian))
      then
        return a1
      end
    end
  end
end

QMAIXT.suoyinE = function(self, w)
  local slot = 0
  local J = {}
  for i = 0x1, self["Ku"]:GetNumSlots() do
    local z = self["Ku"]:GetItemInSlot(i)
    if z and z["prefab"] then
      local K = 0x1
      if J[z["prefab"]] == nil then
        J[z["prefab"]] = 0x0
      end
      if z["replica"]["stackable"] ~= nil then
        K = z["replica"]["stackable"]:StackSize()
      end
      J[z["prefab"]] = J[z["prefab"]] + K
    else
      slot = slot + 1
    end
  end
  local c = self["Ku"]:GetActiveItem()
  if c then
    local K = 0x1
    if J[c["prefab"]] == nil then
      J[c["prefab"]] = 0x0
    end
    if c["replica"]["stackable"] ~= nil then
      K = c["replica"]["stackable"]:StackSize()
    end
    J[c["prefab"]] = J[c["prefab"]] + K
  end
  local backpack = self.Ku:GetOverflowContainer()
  if backpack then
    for i = 0x1, backpack:GetNumSlots() do
      local item = backpack:GetItemInSlot(i)
      if item and item.prefab then
        if J[item.prefab] == nil then
          J[item.prefab] = 0x0
        end
        J[item.prefab] = J[item.prefab] + count(item)
      else
        slot = slot + 1
      end
    end
  end
  if w then
    return J[w] or 0x0, J
  else
    return J, slot
  end
end

QMAIXT.suoyinF = function(self, prefab, tag, fn)
  local slots = {}
  for i = 0x1, self["Ku"]:GetNumSlots() do
    local z = self["Ku"]:GetItemInSlot(i)
    if
      z
      and z["prefab"]
      and (prefab == nil or z.prefab == prefab)
      and (tag == nil or z:HasTag(tag))
      and (fn == nil or fn(z))
    then
      table.insert(slots, i)
    end
  end
  local cslots = {}
  local container = self.Ku:GetOverflowContainer()
  if container then
    for i = 0x1, container:GetNumSlots() do
      local z = container:GetItemInSlot(i)
      if
        z
        and z["prefab"]
        and (prefab == nil or z.prefab == prefab)
        and (tag == nil or z:HasTag(tag))
        and (fn == nil or fn(z))
      then
        table.insert(cslots, i)
      end
    end
  end
  return slots, container, cslots
end

QMAIXT.pack = function(self, islot, cslot, bundle)
  for i, v in pairs(islot) do
    if bundle == nil then
      return false
    end

    if bundle.replica.container:IsFull() then
      break
    end

    self.Ku:MoveItemFromAllOfSlot(v, bundle)
    Sleep(0.3)
  end
  local cc = self.Ku:GetOverflowContainer()
  if cc ~= nil and cslot ~= nil and #cslot > 0 then
    for i, v in pairs(cslot) do
      if bundle == nil then
        return false
      end

      if bundle.replica.container:IsFull() then
        break
      end

      cc:MoveItemFromAllOfSlot(v, bundle)
      Sleep(0.3)
    end
  end

  if bundle == nil or not bundle.replica.container:IsFull() then
    return false
  else
    SendRPCToServer(
      RPC.DoWidgetButtonAction,
      ACTIONS.WRAPBUNDLE.code,
      bundle,
      ACTIONS.WRAPBUNDLE.mod_name
    )
    return true
  end
end

QMAIXT.es = function(self, count)
  local slot = 0
  for i = 0x1, self["Ku"]:GetNumSlots() do
    local item = self["Ku"]:GetItemInSlot(i)
    if item == nil then
      slot = slot + 1
    end
  end

  local backpack = self.Ku:GetOverflowContainer()

  if backpack then
    for i = 0x1, backpack:GetNumSlots() do
      local item = backpack:GetItemInSlot(i)
      if item == nil then
        slot = slot + 1
      end
    end
  end
  if count then
    return slot >= count, slot
  else
    return slot
  end
end

QMAIXT.equip = function(self, tag, percent)
  for k, v in pairs(MYEQUIPSLOTS) do
    local item = self.Ku:GetEquippedItem(v)

    if
      item
      and (tag == nil or item:HasTag(tag))
      and (percent == nil or item.replica.inventoryitem.classified.percentused:value() < percent)
    then
      return item, item.replica.inventoryitem.classified.percentused:value()
    end
  end

  return nil
end

QMAIXT.getgfcoin = function(self)
  return self.inst.replica.gftrade:GetGfCoin()
end

QMAIXT.SetXH = function(self, data)
  if data and type(data) == "table" and data[1] ~= nil then
    self.xhms = data
    self.xgms = data
  else
    self.xhms = nil
    self.xgms = nil
  end
end

QMAIXT.XHMS = function(self, time, fw)
  fw = fw and math.max(fw, 0.05) or 3
  if self.xhms[self.hangxian] == nil then
    self.hangxian = 1
  end
  if self.xhms[self.hangxian] ~= nil then
    local pt = self.xhms[self.hangxian]
    if self.inst:GetDistanceSqToPoint(pt:Get()) < fw * fw then
      self.hangxian = self.hangxian + 1
      if self.xhms[self.hangxian] == nil then
        return true
      end
    else
      self.GoTo(self, pt)
    end
  end
  if time then
    Sleep(time)
  end
end

local function Getpos(pt)
  local map = TheWorld.Map
  for i = 1, 20 do
    local ang = math.random(360)
    local lie = math.random(0, 15)
    local pos = Vector3(math.cos(math.rad(ang)) * lie, 0, math.sin(math.rad(ang)) * lie) + pt
    if map:IsPassableAtPoint(pos:Get()) and not map:IsGroundTargetBlocked(pos) then
      return pos
    end
  end
end

QMAIXT.NKUANG = function(self, time)
  local pt = self.xgms
  if pt then
    if self.inst:GetDistanceSqToPoint(pt:Get()) < 3 * 3 then
      if self.qmtime == nil then
        self.qmtime = GetTime()
      end
      if GetTime() - self.qmtime > (time or 1) then
        local pos = Getpos(pt)
        if pos then
          self.qmtime = nil
          self.GoTo(self, pt)
        end
      end
    end
  end
end

QMAIXT.ToXH = function(self, time)
  if type(self.xhms) == "table" and type(self.xgms) == "table" then
    if self.xhms[2] ~= nil then
      self.XHMS(self)
    elseif self.xgms.x and self.xgms.y and self.xgms.z then
      self.NKUANG(self, time)
    end
  end
  Sleep(0.1)
end

QMAIXT.find = function(self, rn, tbl1, tbl2, tbl3, yushe, fn)
  local x, y, z = self.inst.Transform:GetWorldPosition()
  local tx = type(tbl2) == "table" and tbl2
    or type(tbl2) == "number" and { "FX", "NOCLICK", "DECOR", "INLIMBO" }
    or nil
  local ens = TheSim:FindEntities(x, 0, z, rn, tbl1, tx, tbl3)
  if fn ~= nil or yushe ~= nil then
    local newens = {}
    for i, v in ipairs(ens) do
      if v and v.prefab and (yushe == nil or v.prefab == yushe) and (fn == nil or fn(v)) then
        table.insert(newens, v)
      end
    end
    return newens
  end
  return ens
end

local function cc1(t, v)
  return {}
end
local function cc2(t, v1)
  local newt = {}
  if type(v1) == "string" then
    for k, v in pairs(t) do
      if type(v) == "table" then
        for i, v2 in ipairs(v) do
          if v2 and v2:IsValid() and v2:HasTag(v1) then
            table.insert(newt, v2)
          end
        end
      end
    end
  end
  return newt
end

QMAIXT.findA = function(self, rn, tbl1, tbl2, tbl3, fn)
  local x, y, z = self.inst.Transform:GetWorldPosition()
  local tx = type(tbl2) == "table" and tbl2
    or type(tbl2) == "number" and { "FX", "NOCLICK", "DECOR", "INLIMBO" }
    or nil
  local ens = TheSim:FindEntities(x, 0, z, rn, tbl1, tx, tbl3)
  local newens = {}
  for i, v in ipairs(ens) do
    if v and v.prefab and (fn == nil or fn(v)) then
      if newens[v.prefab] == nil then
        newens[v.prefab] = {}
      end
      table.insert(newens[v.prefab], v)
    end
  end
  setmetatable(newens, { __index = cc1, __call = cc2 })
  return newens
end

QMAIXT.item = function(self, item, num)
  local int1 = 0
  local int2 = 0
  local int3 = 1
  local int4 = num or GetStackSize(item)
  local p = type(item) == "table" and item.prefab or type(item) == "string" and item
  if p and int4 then
    if type(item) == "table" then
      if item.replica.stackable ~= nil then
        int3 = item.replica.stackable:MaxSize() or 20
      end
    end
    for i = 1, self.Ku:GetNumSlots() do
      local a1 = self.Ku:GetItemInSlot(i)
      if a1 and a1.prefab and a1.prefab == p then
        if a1.replica.stackable ~= nil then
          local a2 = a1.replica.stackable:StackSize()
          int3 = a1.replica.stackable:MaxSize() or 20
          local a4 = int3 - a2
          int2 = int2 + a4
        end
      else
        int1 = int1 + 1
      end
    end
    local b1 = int2 + int3 * int1
    return b1 >= int4, b1
  end
end

QMAIXT.moveA = function(self, yushe, co, biaoqian, zhengze)
  if co == nil or not co:IsValid() or co.replica.container == nil then
    return false
  end
  local item, sol = self.suoyinA(self, yushe, biaoqian, zhengze)
  if item and sol then
    self.Ku:MoveItemFromAllOfSlot(sol, co)
    return true
  else
    item, sol, bei = self.suoyinA(self, yushe, biaoqian, zhengze)
    if item and sol and bei then
      bei.replica.container:MoveItemFromAllOfSlot(sol, co)
      return true
    end
    return false
  end
  return false
end

return QMAIXT
