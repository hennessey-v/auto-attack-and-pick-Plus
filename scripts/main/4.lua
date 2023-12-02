-- 自动读挂机服藏宝图
local _lock_huxi_auto_read = "treasuremap"
-- local _lock_huxi_auto_read = "book_sleep"
local str_auto_read = "自动读藏宝图"
local ent_util = require("libs/entutil")
local TIP = require "util/tip"

local autoread = {}
local id_auto_read = "LIGUO_AUTO_READ"
local auto_read_thread
function autoread:StopPutThread(message, color)
    KillThreadsWithID(id_auto_read)
    auto_read_thread = nil
    -- if message ~= "" then
    --     TIP(message or "读藏宝图终止", color or "white",'') 
    -- end
end

function autoread:Fn()
    local p_util = require "libs/playerutil"
    if _lock_huxi_auto_read then
        local bookprefab = _lock_huxi_auto_read
        if not auto_read_thread then
            auto_read_thread = StartThread(function()
                TIP(str_auto_read, "green", true)
                local num = 0
                while auto_read_thread do
                    if num < 9 then
                        repeat
                            Sleep(0.1)
                        until not p_util:IsInBusy()
                        local book = p_util:GetItemFromAll("book_sleep")
                        if book then
                            local act = ACTIONS.READ
                            local buff_act = BufferedAction(ThePlayer, nil, act, book)
                            if act and buff_act then
                                SendRPCToServer(RPC.UseItemFromInvTile, act.code, book)
                                num = num + 1
                            end
                        else
                            autoread:StopPutThread()
                            break
                        end
                    else
                        autoread:StopPutThread()
                    end
                end
                TIP(str_auto_read, "green", "任务结束，读了"..num.."张藏宝图辣", "chat")
            end, id_auto_read)
        end
    end
end

return autoread