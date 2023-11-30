-- 自动读挂机服藏宝图
-- local _lock_huxi_auto_read = "treasuremap"
local _lock_huxi_auto_read = "book_sleep"
local str_auto_read = "自动读藏宝图"
local ent_util = require("libs/entutil")
local TIP = require "util/tip"

-- AddHovererFuncAndIsOut(function(target, prefab, bind, str)
--     if target and target:HasTags({"bookcabinet_item", "book"}) and bind == GLOBAL.ThePlayer and type(str)=="string" and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and string.match(str, GLOBAL.STRINGS.ACTIONS.READ.."$") then
--         _lock_huxi_auto_read = target.prefab
--         AddHovererFuncAndIsOut(function()
--             _lock_huxi_auto_read = false
--             RemoveHovererFuncAndIsOut(true , "_huxi_auto_read")
--         end, true, "_huxi_auto_read")
--         return string.gsub(str, GLOBAL.STRINGS.ACTIONS.READ, str_auto_read)
--     end
-- end)
local autoread = {}
local id_auto_read = "LIGUO_AUTO_READ"
local auto_read_thread
function autoread:StopPutThread(message, color)
    KillThreadsWithID(id_auto_read)
    auto_read_thread = nil
    if message ~= "" then
        TIP(message or "读藏宝图终止", color or "white",'') 
    end
end

function autoread:Fn()
    local p_util = require "libs/playerutil"
    -- AddComponentPostInit("playercontroller", function(self, inst)
    if _lock_huxi_auto_read then
        local bookprefab = _lock_huxi_auto_read
        if not auto_read_thread then
            auto_read_thread = StartThread(function()
                TIP(str_auto_read, "green", true)
                while auto_read_thread do
                    repeat
                        Sleep(3)
                    until not p_util:IsInBusy()
                    local book = p_util:GetItemFromAll(bookprefab)
                    if book then
                        local act = ACTIONS.READ
                        local buff_act = BufferedAction(ThePlayer, nil, act, book)
                        if act and buff_act then
                            buff_act.preview_cb = function()
                                SendRPCToServer(RPC.UseItemFromInvTile, act.code, book)
                            end
                            
                            if self.locomotor then
                                self:DoAction(buff_act)
                            else
                                buff_act.preview_cb()
                            end
                        end
                    else
                        StopPutThread("任务结束")
                        break
                    end
                end
            end, id_auto_read)
        end
    end
    -- end)
end

return autoread

-- InterruptedByMobile(function() return auto_read_thread end, StopPutThread)