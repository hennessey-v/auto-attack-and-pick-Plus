-- 监控特定商品
local TIP = require "util/tip"

local broccoli = {}
local id_monitor = "LIGUO_MONITOR"
local monitor_thread
local productid = 451
local productlist = {
    100,    -- 便携鱼缸
    365,    -- 魔眼装饰
    366,    -- 强化电路 
    451,    -- 粉宝石 
    452,    -- 特价粉宝石
}
-- local productid = GetModConfigData("productid",MOD_EQUIPMENT_CONTROL.MODNAME) --要监控的物品id


local function GetRefreshTime(callback)
    TheSim:QueryServer("http://39.106.52.23:8080/user/mod/time?adminUsername=afk&world=3",
    function(result,isSuccessful,resultCode)
        if isSuccessful and result~=nil then
            result = result + 0
            if result <= 0 then
                callback(0)
            else
                callback(result)
            end
        end
    end,
    "GET")
end

local function GetProductList(callback)
    TheSim:QueryServer("http://39.106.52.23:8080/product/mod/list?adminUsername=afk&world=3&expire=4800&type=1",
        function(result, isSuccessful, resultCode)
            if isSuccessful and result ~= nil then
                local ProductList = json.decode(result)
                callback(ProductList)
            else
                callback(nil)
            end
        end,
        "GET"
    )
end
local function MonitorProducts()
    if monitor_thread then
        GetProductList(function(ProductList)
            if ProductList then
                for i, item in ipairs(ProductList) do
                    for i=0, #(productlist) do
                        if item["id"]==productlist[i] then
                            TIP("小店监控","red","小店里出现了"..item["product"].."！当前剩余库存"..item["stock"].."个","chat")
                        end
                    end
                end
                -- GetRefreshTime(function(refreshTime)
                --     if refreshTime then
                --         if refreshTime == 0 then
                --             Sleep(60)
                --             GetRefreshTime(function(refreshTime)
                --                 if refreshTime then
                --                     Sleep(refreshTime)
                --                 end
                --             end)
                --         end
                --     else
                --         Sleep(60)
                --     end
                -- end)
                Sleep(6)
                MonitorProducts()
            else
                broccoli:StopPutThread("数据获取异常，请稍后重试","red")
            end
        end)
    end
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
        monitor_thread = StartThread(function()
            MonitorProducts()
        end,id_monitor)
    end
end

return broccoli