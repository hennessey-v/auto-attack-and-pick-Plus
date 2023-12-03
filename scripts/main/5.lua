-- 监控特定商品
local TIP = require "util/tip"

local broccoli = {}
local id_monitor = "LIGUO_MONITOR"
local monitor_thread
local productid = GetModConfigData("productid",MOD_EQUIPMENT_CONTROL.MODNAME) --要监控的物品id
-- 粉宝石       451
-- 特价粉宝石   452
-- 强化电路     366
-- 魔眼装饰     365
-- 便携鱼缸     100
local function refreshTime()
    TheSim:QueryServer("http://39.106.52.23:8080/user/mod/time?adminUsername=afk&world=3",
    function(result,isSuccessful,resultCode)
        if isSuccessful and result~=nil then
            result = result + 0
            if result <= 0 then
                return 0
            else
                return result/60/8
            end
        end
    end,
    "GET")
end

local function GetProductList()
    TheSim:QueryServer("http://39.106.52.23:8080/product/mod/list?adminUsername=afk&world=3&expire=4800&type=1",
    function(result,isSuccessful,resultCode)
        if isSuccessful and result~=nil then
            local items = json.decode(result)
            return items
        end
    end,
    "GET")
end


function broccoli:StopPutThread(message, color)
    KillThreadsWithID(id_monitor)
    monitor_thread = nil
    if message ~= "" then
        TIP("小店监控", color or "white",message or "终止") 
    end
end

function broccoli:Fn()
    if not monitor_thread then
        auto_read_thread = StartThread(function()

            while monitor_thread do
                local refreshTime = refreshTime()
                sleep(refreshTime+3)
                local items = GetProductList()
                for i, item in ipairs(items) do
                    if item["id"]==productid then
                        TIP("小店监控","red","小店里出现了"..product.."！当前剩余库存"..item["stock"].."个","chat")
                    end
                end
                sleep(60)
            end
        end,id_monitor)
    end
end

return broccoli