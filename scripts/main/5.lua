-- 小店刷新
local TIP = require "util/tip"

local refreshTime = {}
function refreshTime:Fn()
    TheSim:QueryServer("http://39.106.52.23:8080/user/mod/time?adminUsername=afk&world=3",
    function(result,isSuccessful,resultCode)
        if isSuccessful and result~=nil then
            local text = ""
            result = result + 0
            if result <= 0 then
                text = "小店已重置"
                TIP("迷宫","white","小店已刷新","chat")
            else
                text = "还有"..string.format("%.1f", result/60/8).."天"
                TIP("迷宫","white","小店刷新时间还有"..string.format("%.1f", result/60/8).."天","chat")
            end
            -- local refreshTime = wallet:AddChild(Text(BUTTONFONT, body_font_size, "小店刷新："..text, RGB(50, 50, 50)))
            -- refreshTime:SetPosition(0, 100)
        end
    end,
    "GET")
end

return refreshTime