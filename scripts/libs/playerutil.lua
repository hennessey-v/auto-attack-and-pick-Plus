-- 此文件追加方法无需判断ThePlayer，无player会自动返回nil 
-- p_util ThePlayer
-- i_util inventory
-- b_util builder


local t_util = require "libs/tableutil"
local e_util = require "libs/entutil"
local c_util = require "libs/calcutil"


local i_util = {}
local function getinvent()
    return ThePlayer.replica.inventory
end
-- 有足够的空间将某组物品拿到身上或背包，注意：只能一组
function i_util:CanTakeItem(item)
    local prefab = item and item.prefab
    if not prefab then return end
    local inv = getinvent()
    local size = e_util:GetStacksize(item)
    local maxsize = e_util:GetMaxSize(item)
    if t_util:NumElement(inv:GetNumSlots(), inv:GetItems(), function(slot, inv_item)
        if not inv_item then
            return true
        elseif inv_item.prefab == prefab then
            local inv_size = e_util:GetStacksize(inv_item)
            if size + inv_size <= maxsize then
                return true
            end
        end
    end)then return true end

    local container_file = require("containers")
    return t_util:GetElement(inv:GetOpenContainers(), function(cont_inst)
        if cont_inst and cont_inst:HasTags({"INLIMBO", "backpack"}) then
            local c_prefab = cont_inst.prefab
            local testfunc = (c_prefab and container_file and container_file.params and container_file.params[c_prefab] 
                and type(container_file.params[c_prefab].itemtestfn) == "function")
                and container_file.params[c_prefab].itemtestfn or (function()
                    return true
                end)
            local cont = e_util:GetContainer(cont_inst)
            return cont and t_util:NumElement(cont:GetNumSlots(), cont:GetItems(), function(slot, cont_item)
                if not cont_item then
                    return testfunc(cont_inst, item, slot)
                elseif cont_item.prefab == prefab then
                    local cont_size = e_util:GetStacksize(cont_item)
                    if size + cont_size <= maxsize then
                        return testfunc(cont_inst, item, slot)
                    end
                end
            end)
        end
    end)
end
-- 是否已经打开某个容器
function i_util:IsOpenContainer(cont_inst)
    local invent = getinvent()
    return t_util:GetElement(invent:GetOpenContainers(), function(open_inst)
        return open_inst == cont_inst and e_util:GetContainer(open_inst)
    end)
end


-- 获取鼠标上的物品
function i_util:GetActiveItem(prefab)
    local item = getinvent():GetActiveItem()
    if not prefab or not item then return item end
    local prefabs = type(prefab) == "table" and prefab or {prefab}
    return table.contains(prefabs, item.prefab) and item
end
-- 放下鼠标上的物品
function i_util:ReturnActiveItem()
    return getinvent():ReturnActiveItem()
end
-- 原地丢弃某个物品
function i_util:DropItemFromInvTile(item)
    return getinvent():DropItemFromInvTile(item)
end

-- 获取装备栏的装备
function i_util:GetEquip(slot)
    return getinvent():GetEquippedItem(slot)
end


-- 获取所有物品(物品名，标签，满足函数，获取物品的顺序)
function i_util:GetItemsFromAll(prefab, needtags, func, order)
    local result = {}
    local invent = getinvent()
    local items = {
        body = invent:GetItems(),
        equip = invent:GetEquips(),
        -- hands = self:GetActiveItem(),  不统计鼠标上的物品
        backpack = {},
        container = {},
    }

    for container_inst,_ in pairs(invent:GetOpenContainers())do
        local container = e_util:GetContainer(container_inst)
        if container then
            if container_inst:HasTag("INLIMBO")then
                items.backpack = t_util:MergeList(items.backpack, container:GetItems())
            else
                items.container = t_util:MergeList(items.container, container:GetItems())
            end
        end
    end

    local t = type(order)
    if t == "string" and items[order] then
        order = {order}
    elseif t == "table" then
        -- do nothing
    else
        order = {"container", "backpack", "equip", "body"}
    end


    local all_items = {}
    for _, o in pairs(order)do
        if items[o] then
            all_items = t_util:MergeList(all_items, items[o])
        end
    end

    needtags = type(needtags) == "string" and {needtags} or (type(needtags) == "table" and needtags)
    for _, item in pairs(all_items)do
        if (not prefab or prefab == item.prefab or (type(prefab)=="table" and table.contains(prefab, item.prefab)))
            and (not needtags or item:HasTags(needtags))
            and (not func or func(item)) then
                table.insert(result, item)
        end
    end
    return result
end

-- 获取一个物品
function i_util:GetItemFromAll(prefab, needtags, func, oreder)
    return i_util:GetItemsFromAll(prefab, needtags, func, oreder)[1]
end

-- 获取物品及其容器位置（仅检索物品栏和容器！不检索鼠标和装备栏）
function i_util:GetSlotsFromAll(prefab, needtags, func, order)
    local result = {}
    local invent = getinvent()
    local items = {
        body = {},
        backpack = {},
        container = {},
    }

    for slot, item in pairs(invent:GetItems())do
        items.body[item] = {
            slot = slot,
            container = ThePlayer,
        }
    end

    for container_inst,_ in pairs(invent:GetOpenContainers())do
        local container = e_util:GetContainer(container_inst)
        if container then
            if container_inst:HasTag("INLIMBO")then
                for slot, item in pairs(container:GetItems())do
                    items.backpack[item] = {
                        slot = slot,
                        container = container_inst,
                    }
                end
            else
                for slot, item in pairs(container:GetItems())do
                    items.container[item] = {
                        slot = slot,
                        container = container_inst,
                    }
                end
            end
        end
    end

    local t = type(order)
    if t == "string" and items[order] then
        order = {order}
    elseif t == "table" then
        -- do nothing
    else
        order = {"container", "backpack", "body"}
    end


    local all_items = {}
    for _, o in pairs(order)do
        if items[o] then
            all_items = t_util:MergeMap(all_items, items[o])
        end
    end

    needtags = type(needtags) == "string" and {needtags} or (type(needtags) == "table" and needtags)
    for item, slots in pairs(all_items)do
        if (not prefab or prefab == item.prefab or (type(prefab)=="table" and table.contains(prefab, item.prefab)))
            and (not needtags or item:HasTags(needtags))
            and (not func or func(item)) then
                result[item] = slots
        end
    end
    return result
end
-- item:物品 slot:位置 container:cont_inst
function i_util:GetSlotFromAll(prefab, needtags, func, order)
    local item, slots = next(i_util:GetSlotsFromAll(prefab, needtags, func, order))
    return item and {
        item = item, 
        slot = slots.slot,
        container = slots.container,
    }
end


local p_util = {}

-- 点击一下
function p_util:Click(ent, right)
    local pos
    if e_util:IsValid(ent) then
        pos = ent:GetPosition()
    elseif not ent then
        assert(ent, "非法实体或位置！")
    elseif ent.x and ent.z then
        pos = ent
        ent = nil
    end
    local picker = ThePlayer.components.playeractionpicker
    local controller = ThePlayer.components.playercontroller
    if pos and picker and controller then
        local _, act 
        if right then
            _, act  = next(picker:GetRightClickActions(pos, ent))
        else
            _, act  = next(picker:GetLeftClickActions(pos, ent))
        end
        if not act then
            act = BufferedAction(ThePlayer, ent, ACTIONS.WALKTO, nil, pos)
            right = nil
        end
        act.preview_cb = function()
            if right then
                SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target, 
                -- rotation, isreleased, controlmods, noforce, mod_name, platform, platform_relative
                act.rotation, nil, nil, true, act.action.mod_name)
            else
                SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, act.target, 
                -- isreleased, controlmods, noforce, mod_name, platform, platform_relative, spellbook, spell_id
                nil, nil, true, act.action.mod_name)
            end
        end
        if controller.locomotor then
            controller:DoAction(act)
        else
            act.preview_cb()
        end
        return act
    end
end
local function getactid(act)
    return act and act.action and act.action.id
end
-- 动作点击
-- 传入ent和actid，如果左键或右键动作符合actid则执行，否则会模拟点击，优先左键还是右键需要传入tryright判断
function p_util:ActClick(ent, actid, tryright)
    local pos
    local _ent = ent
    if e_util:IsValid(ent) then
        pos = ent:GetPosition()
    elseif not ent then
        assert(ent, "非法实体或位置！")
    elseif ent.x and ent.z then
        pos = ent
        ent = nil
    end
    local picker = ThePlayer.components.playeractionpicker
    local controller = ThePlayer.components.playercontroller
    if pos and picker and controller then
        local lmb,rmb = picker:DoGetMouseActions(pos, ent)
        local right,act
        if tryright then
            if getactid(rmb) == actid then
                right = true
                act = rmb
            else
                act = getactid(lmb) == actid and lmb
            end
        else
            if getactid(lmb) == actid then
                act = lmb
            else
                if getactid(rmb) == actid then
                    right = true
                    act = rmb
                end
            end
        end
        if act then
            act.preview_cb = function()
                if right then
                    SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target,act.rotation, nil, nil, true, act.action.mod_name)
                else
                    SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, act.target,nil, nil, true, act.action.mod_name)
                end
            end
            if controller.locomotor then
                controller:DoAction(act)
            else
                act.preview_cb()
            end
            return act
        else
            return p_util:Click(_ent, tryright)
        end
    end
end

-- 能点就点，点不了会返回，返回能不能点
function p_util:TryClick(ent, actid)
    local pos
    if e_util:IsValid(ent) then
        pos = ent:GetPosition()
    elseif not ent then
        assert(ent, "非法实体或位置！")
    elseif ent.x and ent.z then
        pos = ent
        ent = nil
    end
    local actid = type(actid) == "table" and actid or {actid}
    local picker = ThePlayer.components.playeractionpicker
    local controller = ThePlayer.components.playercontroller
    if pos and picker and controller then
        local lmb,rmb = picker:DoGetMouseActions(pos, ent)
        local right,act
        if table.contains(actid, getactid(rmb)) then
            right = true
            act = rmb
        else
            act = table.contains(actid, getactid(lmb)) and lmb
        end
        if act then
            act.preview_cb = function()
                if right then
                    SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target,act.rotation, nil, nil, true, act.action.mod_name)
                else
                    SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, act.target,nil, nil, true, act.action.mod_name)
                end
            end
            if controller.locomotor then
                controller:DoAction(act)
            else
                act.preview_cb()
            end
        end
        return act
    end
end

-- 获取左键和右键点击的动作id，返回nil或table
function p_util:GetActionIDs(ent)
    local pos
    if e_util:IsValid(ent) then
        pos = ent:GetPosition()
    elseif ent.x and ent.z then
        pos = ent
        ent = nil
    elseif not ent then
        return
    end
    local picker = ThePlayer.components.playeractionpicker
    if pos and picker then
        local lmb,rmb = picker:DoGetMouseActions(pos, ent)
        return {getactid(lmb), getactid(rmb)}
    end
end

-- 判断玩家是否正忙
function p_util:IsInBusy()
    return  -- e_util:IsAnim({"pickup", "pickup_pst"}, ThePlayer) or 
            (ThePlayer.sg and ThePlayer.sg:HasStateTag("moving")) or
            (ThePlayer:HasTag("moving") and not ThePlayer:HasTag("idle"))or
            ThePlayer.components.playercontroller:IsDoingOrWorking()
end


-- pc绑定事件
function p_util:SetBindEvent(eventname, func)
    ThePlayer.player_classified:RemoveEventCallback(eventname, func)
    ThePlayer.player_classified:ListenForEvent(eventname, func)
end

-- 玩家死了吗
function p_util:IsDead()
    return ThePlayer.player_classified.isghostmode:value()
end


-- 玩家攻击范围
function p_util:GetAttackRange()
    return ThePlayer.replica and ThePlayer.replica.combat and ThePlayer.replica.combat:GetAttackRangeWithWeapon()
end

-- 是否在玩家攻击范围内
function p_util:CanAttack(target)
    if e_util:IsValid(target) then
        local w_range = p_util:GetAttackRange() or 2
        local can_dist = w_range + target:GetPhysicsRadius(0)
        local dist = e_util:GetDist(target)
        return dist and dist<can_dist
    end
end


local function getPrefabInvs(prefab, invs)
    local t = {}
    if type(invs) == "table" then
        for _, inv in ipairs(invs)do
            if inv.tile and inv.tile.item and inv.tile.item.prefab == prefab then
                table.insert(t, inv)
            end
        end
    end
    return t
end

-- 获取玩家身上的某东西的所有格子
function p_util:GetPrefabSlotsWithInvAndBackPack(prefab)
    local slots = {}
    local controls = ThePlayer.HUD and ThePlayer.HUD.controls
    if controls then
        local invs =  controls.inv and controls.inv.inv
        slots = t_util:MergeList(slots, getPrefabInvs(prefab, invs))
        local equip = i_util:GetEquip("back") or i_util:GetEquip("body")
        if equip and equip:HasTag("backpack") then
            local backpack_invs = controls.containers and controls.containers[equip] and controls.containers[equip].inv
            slots = t_util:MergeList(slots, getPrefabInvs(prefab, backpack_invs))
        end
    end
    return slots
end






local b_util = {}
local function getbuilder()
    return ThePlayer.replica.builder
end

-- 能否制作
function b_util:CanBuild(recipename)
    local recipe = GetValidRecipe(recipename)
    if recipe then
        local builder = getbuilder()
        local knows_recipe = builder:KnowsRecipe(recipe)
        if builder:IsFreeBuildMode() then return true end
		local tech_trees = builder:GetTechTrees()
        local should_hint_recipe = ShouldHintRecipe(recipe.level, tech_trees)
        local is_build_tag_restricted = not builder:CanLearn(recipe.name)
        if knows_recipe or should_hint_recipe then
            if builder:IsBuildBuffered(recipe.name) and not is_build_tag_restricted then
                return true
            elseif knows_recipe or CanPrototypeRecipe(recipe.level, tech_trees) then
                for i, v in ipairs(recipe.ingredients) do
                    if not builder.inst.replica.inventory:Has(v.type, math.max(1, RoundBiasedUp(v.amount * builder:IngredientMod())), true) then
                        return false
                    end
                end
                for i, v in ipairs(recipe.character_ingredients) do
                    if not builder:HasCharacterIngredient(v) then
                        return false
                    end
                end
                return true
            end
        end
    end
end

-- 制作
function b_util:MakeSth(recipename, skin)
    local recipe = GetValidRecipe(recipename)
    return recipe and getbuilder():MakeRecipeFromMenu(recipe, skin)
end









local r_util = {}
for name, func in pairs(p_util)do
    r_util[name] = function(...)
        return ThePlayer and ThePlayer.player_classified and func(...)
    end
end
for name, func in pairs(i_util)do
    r_util[name] = function(...)
        return ThePlayer and getinvent() and func(...)
    end
end
for name, func in pairs(b_util)do
    r_util[name] = function(...)
        return ThePlayer and getbuilder() and func(...)
    end
end

return r_util