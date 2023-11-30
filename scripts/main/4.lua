-- 自动读挂机服藏宝图
local _lock_huxi_auto_read
local str_auto_read = GLOBAL.STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.DEFAULT..GLOBAL.STRINGS.ACTIONS.READ
local ent_util = require("libs/entutil")

AddHovererFuncAndIsOut(function(target, prefab, bind, str)
    if target and target:HasTags({"bookcabinet_item", "book"}) and bind == GLOBAL.ThePlayer and type(str)=="string" and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and string.match(str, GLOBAL.STRINGS.ACTIONS.READ.."$") then
        _lock_huxi_auto_read = target.prefab
        AddHovererFuncAndIsOut(function()
            _lock_huxi_auto_read = false
            RemoveHovererFuncAndIsOut(true , "_huxi_auto_read")
        end, true, "_huxi_auto_read")
        return string.gsub(str, GLOBAL.STRINGS.ACTIONS.READ, str_auto_read)
    end
end)
local id_auto_read = "HUXI_AUTO_READ"
local auto_read_thread
local function StopPutThread(message, color)
    GLOBAL.KillThreadsWithID(id_auto_read)
    auto_read_thread = nil
    if message ~= "" then
        TIP(message or "读书终止", color or "white") 
    end
end


local p_util = require "libs/playerutil"
AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= GLOBAL.ThePlayer then return end
    local _OnRightClick = self.OnRightClick
    self.OnRightClick = function(self, down, ...)
        if not down and _lock_huxi_auto_read then
            local bookprefab = _lock_huxi_auto_read
            if not auto_read_thread then
                auto_read_thread = GLOBAL.StartThread(function()
                    TIP(str_auto_read, "green", true)
                    while auto_read_thread do
                        repeat
                            GLOBAL.Sleep(GLOBAL.FRAMES*3)
                        until not p_util:IsInBusy()
                        local book = GetItemFromAll(bookprefab, nil, function(ent)
                            local nowperc = ent_util:GetPercent(ent)
                            local bookclone = ent_util:ClonePrefab(bookprefab)
                            local total = bookclone and bookclone.components.finiteuses and bookclone.components.finiteuses.total
                            return type(total) == "number" and nowperc > 100/total 
                        end)
                        if book then
                            local act = GLOBAL.ACTIONS.READ
                            local buff_act = GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, act, book)
                            if act and buff_act then
                                buff_act.preview_cb = function()
                                    GLOBAL.SendRPCToServer(GLOBAL.RPC.UseItemFromInvTile, act.code, book)
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
        return _OnRightClick(self, down, ...)
    end
end)

InterruptedByMobile(function() return auto_read_thread end, StopPutThread)