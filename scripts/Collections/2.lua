--
-- 猪王交易 换断桩
--

local TIP = require "util/tip"


-- 右键操作视野中的
function UseItemOnScene(item, act)
    local inventory = ThePlayer.components.inventory
    if inventory then 
        inventory:ControllerUseItemOnSceneFromInvTile(item, act.target, act.action.code, act.action.mod_name)
    else 
        ThePlayer.components.playercontroller:RemoteControllerUseItemOnSceneFromInvTile(act, item)
    end
end
-- 寻找附近
local function find_pigking(inst)
    return inst.prefab == "pigking"
end

-- 获取容器
function GetDefaultCheckingContainers()
    return ThePlayer and {
        ThePlayer.replica.inventory:GetActiveItem(),
        ThePlayer.replica.inventory,
        ThePlayer.replica.inventory:GetOverflowContainer()
    } or {}
end
--- copy Tony --
function is_entity(t)
    return t and t.is_a and t:is_a(EntityScript)
end
-- 获取一个物品从容器
function GetItemFromContainers(containers, item, get_all)

    containers = containers or GetDefaultCheckingContainers()

    local final_items = {}

    for _, container in orderedPairs(containers) do
        if type(container) == "table" then
            if is_entity(container)then
                if get_all then
                    table.insert(final_items, {item = container})
                else
                    containers.__orderedIndex = nil
                    return container
                end
            elseif container.GetItems then
                local items = container:GetItems()
                for i, v in orderedPairs(items) do
                    if get_all then
                        table.insert(final_items, {slot = i, item = v, container = container.inst})
                    else
                        items.__orderedIndex = nil
                        containers.__orderedIndex = nil
                        return v, i, container
                    end
                end
            end
        end
    end
    if get_all and #final_items > 0 then
        return final_items
    end

end

local trinket_37 = function()
    TIP("测试","green", "开始运行")  
    local tool = "twings"
    local ThePlayer = ThePlayer
    -- ActionQueuer = ThePlayer.components.actionqueuer
    -- if not ActionQueuer then
    --     TIP("测试","red", "未安装行为排队论！")  
    -- return end

    local pigking = FindEntity(ThePlayer, pigking_RANGE, find_pigking)
    if not pigking then 
        TIP("测试","red", "未发现猪王")  
        return '测试'
    end

    UseItemOnScene(tool, BufferedAction(ThePlayer, pigking, ACTIONS.GIVE, tool))
    -- ThePlayer.components.playercontroller:RemoteControllerUseItemOnSceneFromInvTile("meat", BufferedAction(ThePlayer, pigking, ACTIONS.GIVE, "meat"))
    TIP("测试","green", "完成")  
end

return trinket_37