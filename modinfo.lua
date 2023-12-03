name = "auto attack and pick Plus"
version = "0.0.6"

description = [[
    功能：
    - 自动挂机打怪，自动拾取资源。
    瞎玩挂机服专供：
    - 自动和猪王换断桩（暂和自动攻击捡资源不兼容）
    - 迷宫自动读藏宝图（最多9张）
    - 迷宫小店物品刷新提醒（需手动开启）

    其他功能开发中...
    
    【按键提示】
    UP   自动捡资源/种子
    DOWN 自动攻击怪物
    H    打开面板
    
    建议不要使用具有相同的mod，否则可能出现未知问题

    -- Todo
    - 瞎玩挂机服特价粉宝石提醒
    - 挂机自动行走模式：方块 米字 随机
    - 游戏内配置拾取资源
    
特别感谢：
    https://steamcommunity.com/sharedfiles/filedetails/?id=2416281184
    https://github.com/tomoya92/dstmod-tutorial
    https://www.jianshu.com/p/7cb9b3f1c4cc
]]

author = "Rainea"
forumthread = ""
api_version = 10
--icon_atlas = ".xml" todo
--icon = ".tex" todo
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true
-----------------------------------------------------------------------------------
-- dev 
folder_name = folder_name or "command_manager"
if not folder_name:find("workshop-") then
    name = name .. " -dev"
end
-----------------------------------------------------------------------------------
-- 按键
local string = ""
local keys = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","LAlt","RAlt","LCtrl","RCtrl","LShift","RShift","Tab","Capslock","Space","Minus","Equals","Backspace","Insert","Home","Delete","End","Pageup","Pagedown","Print","Scrollock","Pause","Period","Slash","Semicolon","Leftbracket","Rightbracket","Backslash","Up","Down","Left","Right"}
local keylist = {}
for i = 1, #keys do
    keylist[i] = {description = keys[i], data = "KEY_"..string.upper(keys[i])}
end

keylist[#keys + 1] = {description = "关闭", data = "close"}
-----------------------------------------------------------------------------------
-- 分段标题
local function addTitle(title)
	return {
		name = "null",
		label = title,
		hover = nil,
		options = {
				{ description = "", data = 0 }
		},
		default = 0,
	}
end
-----------------------------------------------------------------------------------

configuration_options = {
addTitle("按键设置"),
    {
        name = "key_toggle",
        hover = "面板开关\n 自动换断桩在面板中",
        label = "面板快捷键",
        options = keylist,
        default = "KEY_H",
    },
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
        label = "设置自动攻击键",
        options = keylist,
        default = "KEY_DOWN"
    },
addTitle("自动拾取设置"), 
    ---------------------自动拾取策略 begin
    {
        name = "PickFirst", --拾取优先
        hover = "当同时开启自动拾取和自动攻击时设置才有效,可以更高效率的捡东西",
        label = "优先拾取（请看上面说明）",
        options = {
        { description = "优先拾取", data = true , hover = "默认值"},
        { description = "攻击后拾取", data = false },
        },
        default = true
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
addTitle("其他设置"),
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
	{
		name = "sw_tip",
		label = "屏幕提示",
		hover = "部分提示语句的显示位置",
		options = {
			{description = "开启", data = "head", hover = "默认, 语句将会出现在人物头顶"},
			{description = "自己的聊天栏", data = "chat", hover = "在聊天栏的位置(仅自己可见)"},
			{description = "全局的聊天栏", data = "announce", hover = "警告：所有人都能看到你的提示消息！"},
			{description = "关闭", data = false},
		},
		default = "head",
	},
    {
        name = "productid",
        hover = "瞎玩挂机服迷宫小店监控物品",
        label = "监控物品",
        options = {
            { description = "粉宝石", data = 451 },
            { description = "特价粉宝石", data = 452 , hover = "默认值"},
            { description = "强化电路", data = 366 },
            { description = "魔眼装饰", data = 365 },
            { description = "便携鱼缸", data = 100 },
        },
        default = 452
    },
-- addTitle("开发设置"),
--     {
--         name = "key_toggle",
--         label = "Tech快捷键",
--         options = keylist,
--         default = "KEY_H",
--     }
}

