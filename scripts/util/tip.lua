local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end

COLORS = {
    WHITE   = RGB(255, 255, 255),
    BLACK   = RGB(0, 0, 0),
    RED     = RGB(207, 61, 61),
    PINK    = RGB(255, 192, 203),
    YELLOW  = RGB(255, 255, 0),
    BLUE    = RGB(0, 0, 255),
    GREEN   = RGB(59, 222, 99),
    PURPLE  = RGB(184, 87, 198),
    BROWN   = RGB(127, 76, 51),
}
function InGame()
    return ThePlayer and  ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus()
end

function Say(str)
    local talker = ThePlayer.components.talker
    if talker then
        talker:Say(str)
    end
end

return function(stat, color, content, way)
    local loca = GetModConfigData("sw_tip",LIGUO_MOD_CONFIG.MODNAME)
    if not loca then return end
    local tcolor = COLORS[string.upper(color)]
    if way then loca = way end
    if type(content) == "boolean" and content then content = "开启" end
    if type(content) == "boolean" and not content then content = "关闭" end

    if InGame() and ThePlayer.components.talker then
        if loca == "announce" then
            TheNet:Say(stat.."："..content)
        elseif loca == "head" then
            ThePlayer.components.talker:Say(stat.."："..content,nil,nil,nil,nil,tcolor)
        elseif loca == "chat" then
            ChatHistory:AddToHistory(ChatTypes.Message, nil, nil, stat, content, tcolor)
        else
            ThePlayer.components.talker:Say(stat.."："..content,nil,nil,nil,nil,tcolor)
        end
    end
end
