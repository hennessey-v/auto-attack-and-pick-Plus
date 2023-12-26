-- 监控特定商品
local TIP = require "util/until-tip"

local broccoli = {}
local id_monitor = "LIGUO_MONITOR"
local monitor_thread
local productlist = {
    -- 100,    -- 便携鱼缸
    365,    -- 魔眼装饰
    366,    -- 强化电路 
    -- 451,    -- 粉宝石 
    452,    -- 特价粉宝石
}
-- local productid = GetModConfigData("productid",MOD_EQUIPMENT_CONTROL.MODNAME) --要监控的物品id


local function GetRefreshTime(callback)
    TheSim:QueryServer(LIGUO_MOD_CONFIG.APIURL.."/user/mod/time?adminUsername="..LIGUO_MOD_CONFIG.ADMIN.."&world=3",
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
    local combinedProductList = {}  -- 用于存储合并后的产品列表
    local requestsCompleted = 0      -- 用于追踪已完成的请求数量

    local function handleRequest(result, isSuccessful)
        requestsCompleted = requestsCompleted + 1  -- 每次请求完成时增加计数器

        if isSuccessful and result ~= nil then
            local productList = json.decode(result)
            if productList then
                -- 合并到主列表
                for _, product in ipairs(productList) do
                    table.insert(combinedProductList, product)
                end
            end
        end

        -- 所有请求都完成时调用回调函数
        if requestsCompleted == 2 then
            callback(combinedProductList)
        end
    end

    -- 发起第一个请求
    TheSim:QueryServer(LIGUO_MOD_CONFIG.APIURL.."/product/mod/list?adminUsername="..LIGUO_MOD_CONFIG.ADMIN.."&world=1&expire=4800&type=1",
        function(result, isSuccessful, resultCode)
            handleRequest(result, isSuccessful)
        end,
        "GET"
    )

    -- 发起第二个请求
    TheSim:QueryServer(LIGUO_MOD_CONFIG.APIURL.."/product/mod/list?adminUsername="..LIGUO_MOD_CONFIG.ADMIN.."&world=3&expire=4800&type=1",
        function(result, isSuccessful, resultCode)
            handleRequest(result, isSuccessful)
        end,
        "GET"
    )
end

local function MonitorProducts()
    if not monitor_thread then
        return
    end

    GetProductList(function(ProductList)
        if not ProductList then
            broccoli:StopPutThread("数据获取异常，请稍后重试", "red")
            return
        end

        for i, item in ipairs(ProductList) do
            for _, productId in ipairs(productlist) do
                if item["id"] == productId and item["stock"] ~= 0 then
                    TIP("小店监控", "red", "小店里出现了" .. item["product"] .. "！当前剩余库存" .. item["stock"] .. "个", "chat")
                end
            end
        end

        GetRefreshTime(function(refreshTime)
            local delayTime = refreshTime+5 or 60
            ThePlayer:DoTaskInTime(delayTime, MonitorProducts)
        end)
    end)
end


function broccoli:StopPutThread(message, color)
    KillThreadsWithID(id_monitor)
    monitor_thread = nil
    if message ~= "" then
        TIP("小店监控", color or "white",message or "停止") 
    end
end

function broccoli:Fn()
    if not monitor_thread then
        monitor_thread = StartThread(function()
            TIP("小店监控","green","启动") 
            MonitorProducts()
        end,id_monitor)
    end
end

return broccoli