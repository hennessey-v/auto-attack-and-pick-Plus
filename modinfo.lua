name = "auto attack and pick Plus"
author = "Rainea"
version = "0.0.2"
forumthread = ""
description = [[
    自动挂机打怪，自动拾取资源。其他功能开发中。。。
    
    UP 自动捡资源/种子
    DOWN 自动攻击怪物
    
    建议不要使用具有相同的mod，否则可能出现未知问题

    -- Todo
    - 挂机自动行走模式：方块 米字 随机
    - 自动和猪王交易
    - 面板控制
    - 游戏内配置拾取资源
    
特别感谢：
    https://steamcommunity.com/sharedfiles/filedetails/?id=2416281184
    https://github.com/tomoya92/dstmod-tutorial
    https://www.jianshu.com/p/7cb9b3f1c4cc
]]
api_version = 10
--icon_atlas = ".xml" todo
--icon = "cbdz0.tex" todo
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

local string = ""
local keys = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","LAlt","RAlt","LCtrl","RCtrl","LShift","RShift","Tab","Capslock","Space","Minus","Equals","Backspace","Insert","Home","Delete","End","Pageup","Pagedown","Print","Scrollock","Pause","Period","Slash","Semicolon","Leftbracket","Rightbracket","Backslash","Up","Down","Left","Right"}
local keylist = {}
for i = 1, #keys do
    keylist[i] = {description = keys[i], data = "KEY_"..string.upper(keys[i])}
end

keylist[#keys + 1] = {description = "关闭", data = "close"}

-- 标题函数
local function AddSection(title)
    return { label = title, name = "", options = { { description = "", data = 0 } }, default = 0, hover = "" }
end


configuration_options = {

    AddSection("按键设置"),

    {
        name = "PickKey",
        hover = "设置自动拾取\n",
        label = "设置自动拾取键",
        options = keylist,
        default = "KEY_UP"
    },
    {
        name = "AttackKey",
        hover = "自动攻击键\n The key to open auto attack mode.",
        label = "设置自动攻击键 Auto Attack key",
        options = keylist,
        default = "KEY_DOWN"
    },

    AddSection("自动拾取设置"),
    
    ---------------------自动拾取策略 begin
    {
        name = "PickFirst", --拾取优先
        hover = "开启自动拾取和自动攻击时设置才有效,可以更高效率的捡东西，且不会被攻击",
        label = "优先拾取（请看上面说明）",
        options = {
        { description = "是", data = true },
        { description = "否", data = false , hover = "默认值"},
        },
        default = false
    },

    {
        name = "PickResources", -- 自动拾取资源
        hover = "大肉，小肉，怪物肉，象鼻，蜘蛛丝，蜘蛛卵，齿轮，各种原力",
        label = "自动拾取:拾取资源",
        options = {
        { description = "是", data = true , hover = "默认值"},
        { description = "否", data = false },
        },
        default = true
    },
    
    {
        name = "PickSeeds", -- 自动拾取种子
        hover = "自动拾取:拾取种子",
        label = "自动拾取:拾取种子",
        options = {
        { description = "是", data = true , hover = "默认值"},
        { description = "否", data = false },
        },
        default = true
    },
    ---------------------自动拾取策略 end

    AddSection("其他设置"),

    {
        name = "UsedRange", --拾取优先
        hover = "自动攻击的索敌距离和拾取资源的范围",
        label = "攻击索敌和资源拾取距离",
        options = {
        { description = "10", data = 10 },
        { description = "20", data = 20 , hover = "默认值"},
        { description = "30", data = 30 },
        { description = "40", data = 40 },
        },
        default = 20
    },
}

