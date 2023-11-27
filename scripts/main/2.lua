-- 猪王交易 换断桩
local e_util = require "libs/entutil"
local p_util = require "libs/playerutil"
local t_util = require "libs/tableutil"
local move = require "util/move"

local exchange = {}
local needprefab = "twigs"
local thread
local id_thread = "LIGUO_AUTO_EXCHANGE"

------------------ 我是可爱的分界线 ----------------------

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

-- local function TIPS(str)
--     TIP("自动换断桩", "yellow", str)
-- end
function exchange:StopThread(message)
    KillThreadsWithID(id_thread)
    if thread then
        -- TIPS(message or "结束！")
        playersay("自动换断桩,结束！")
    end
    thread = nil
end

function exchange:Fn()
    local npc =
        e_util:FindEnt(
        nil,
        "pigking"
        -- ,nil, nil, nil, nil, nil, function(npc) return e_util:FindEnt(npc, "moonstorm_static", 4) end
    )
    if not npc then
        -- return TIP("自动换断桩", "red", "无法启动, 找不到猪王", "chat")
        return playersay("自动换断桩:无法启动, 找不到猪王")

    end
    thread =
        StartThread(
        function()
            while thread and e_util:IsValid(npc) do
                if needprefab then
                    local act_item = p_util:GetActiveItem()
                    if act_item then
                        if act_item.prefab ~= needprefab then
                            local newit = p_util:GetSlotFromAll(needprefab)
                            if newit then
                                local cont = e_util:GetContainer(newit.container)
                                if cont then
                                    cont:SwapActiveItemWithSlot(newit.slot)
                                end
                            else
                                -- TIP("自动换断桩", "green", "树枝呢？没树枝你拿py换吗", "chat")
                                playersay("自动换断桩:树枝呢？没树枝你拿py换吗")
                            end
                        else
                            p_util:TryClick(npc, "GIVE")
                        end
                    else
                        local newit = p_util:GetSlotFromAll(needprefab)
                        if newit then
                            local cont = e_util:GetContainer(newit.container)
                            if cont then
                                cont:TakeActiveItemFromAllOfSlot(newit.slot)
                            end
                            p_util:TryClick(npc, "GIVE")
                        else
                            -- TIP("自动换断桩", "green", "树枝呢？没树枝你拿py换吗", "chat")
                            playersay("自动换断桩:树枝呢？没树枝你拿py换吗")
                        end
                    end
                else
                    -- TIP("自动换断桩", "red", "笨蛋，问问果哥哪出错了", "chat")
                    playersay("笨蛋，问问果哥哪出错了")
                end
                Sleep(5)
                move(math.random(1, 2), math.random(1, 2))
                Sleep(120)
            end
            StopThread()
        end,
        id_thread
    )
end

return exchange
