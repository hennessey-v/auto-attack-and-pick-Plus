-- 下面4行从饥荒的源代码中引入界面开发需要的控件，包括图片、图片按钮、文本和窗口
local WidgetImage = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TIP = require "util/until-tip"

local AutoSwap = require "main/2"--自动换断桩
local AutoRead = require "main/3"--自动读藏宝图
local Monitor = require "main/4"--小店监控
-- local Monitor = require "main/6"

-- 新建一个名为NoMuTechWidget的窗口类，即我们所要显示的对话框
local TechWidget = Class(Widget, function(self)
    Widget._ctor(self, "TechWidget")

    -- 窗口是一个树形结构，先建立一个名为ROOT的窗口根节点，保存在类变量self.root中
    self.root = self:AddChild(Widget("ROOT"))
    self.mainwidget = self.root:AddChild(self:MainWidget())

    self.mainwidget.OnMouseButton = function(_self, button, down, x, y)    --注意:此处应将self.drag_button替换为你要拖拽的widget
        if button == MOUSEBUTTON_RIGHT and down then    --鼠标右键按下
             _self.draging = true    --标志这个widget正在被拖拽，不需要可以删掉
            _self:FollowMouse()     --开启控件的鼠标跟随
        elseif button == MOUSEBUTTON_RIGHT then            --鼠标右键抬起
            _self.draging = false        --标志这个widget没有被拖拽，不需要可以删掉
            _self:StopFollowMouse()        --停止控件的跟随
        end
    end
    
end)

function TechWidget:MainWidget()
    local mainwidget = Widget("mainwidget")

    -- 设置root垂直方向的锚点，ANCHOR_MIDDLE表示中心锚点，ANCHOR_TOP表示顶部锚点，ANCHOR_BOTTOM表示底部锚点
    mainwidget:SetVAnchor(ANCHOR_MIDDLE)
    -- 设置root水平方向的锚点，ANCHOR_MIDDLE表示中心锚点，ANCHOR_LEFT表示左端锚点，ANCHOR_RIGHT表示右端锚点
    mainwidget:SetHAnchor(ANCHOR_MIDDLE)
    -- 设置root的缩放模式，SCALEMODE_PROPORTIONAL表示根据窗口大小按比例缩放
    mainwidget:SetScaleMode(SCALEMODE_PROPORTIONAL)
    -- 设置root的位置，在中心锚点的情况下，（0, 0, 0）表示居中显示
    mainwidget:SetPosition(0, 0, 0)
    -- 下面几行定义对话框背景（半透明黑遮罩）的位置和大小，可以根据按钮的数量和个人喜好调整位置和大小
    local TechBG_pos_x = 0;
    local TechBG_pos_y = 0;
    local TechBG_size_x = 200;
    local TechBG_size_y = 260;
    -- 遮罩为由images/ui.xml和black.tex描述的一张图片
    local TechBG = mainwidget:AddChild(WidgetImage("images/ui.xml", "black.tex"))
    -- 下面几行设置遮罩的缩放尺度、位置、大小和透明度
    TechBG:SetScale(1, 1, 1)
    TechBG:SetPosition(TechBG_pos_x, TechBG_pos_y, 0)
    TechBG:SetSize(TechBG_size_x, TechBG_size_y)
    TechBG:SetTint(1, 1, 1, 0.6)

    --定义对话框的标题，即内容为“Tech”，字体为BODYTEXTFONT，大小为50的文本
    local title_text = TechBG:AddChild(Text(BODYTEXTFONT, 50, '设置'))
    -- 设置标题的位置，TechBG_size_y / 2为遮罩的顶端，我们这里做一个25大小的下偏移，给顶部留点空间
    title_text:SetPosition(0, TechBG_size_y / 2 - 25, 0)

    -- 由于添加按钮有一些共用的代码，我们这里写一个函数来添加按钮
    -- name为按钮的文本，click_fn为按钮点击后的响应函数，x和y为按钮的位置
    local function AddButton(name, click_fn, x, y)
        -- 按钮由一系列图片组成包括一般形态、鼠标悬停形态、鼠标点击形态、禁用形态等，这里使用饥荒现有的按钮样式
        local button = mainwidget:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        -- 调整一下按钮图片的大小
        button.image:SetScale(.6)
        -- 设置按钮的文本字体
        button:SetFont(CHATFONT)
        -- 设置按钮的位置，颜色，响应函数，文本大小，文本
        button:SetPosition(x, y, 0)
        button.text:SetColour(0, 0, 0, 1)
        button:SetOnClick(click_fn)
        button:SetTextSize(30)
        button:SetText(name)
    end

    -- 与夜视类似，营养视角也需要变量来记录当前状态
    local nutrient_mode = 0;
    local autoAttack_mode = 0;
    local AutoSwap_mode = 0;
    local AutoRead_mode = 0;
    local Monitor_mode = 0;
    -- 定义我们要添加的按钮
    local button_settings = {
        -- 切换营养视角
        -- {
        --     name = "切换营养视角",
        --     fn = function()
        --         nutrient_mode = 1 - nutrient_mode;
        --         if nutrient_mode == 0 then
        --             ThePlayer.components.playervision:ForceNutrientVision(false)
        --             return '切换营养视角【关】'
        --         else
        --             ThePlayer.components.playervision:ForceNutrientVision(true)
        --             return '切换营养视角【开】'
        --         end
        --     end
        -- },
        -- 打开作物图鉴，打开后关闭当前对话框
        -- {
        --     name = '打开作物图鉴',
        --     fn = function()
        --         POPUPS.PLANTREGISTRY.fn(ThePlayer, true)
        --         self:Close()
        --     end
        -- },
        -- 自动攻击on
        -- {
        --     name = '自动攻击开【测试】',
        --     fn = function()
        --         autoAttack_mode = 1 - autoAttack_mode;
        --         if autoAttack_mode == 0 then 
        --             -- auto('OffAttack')
        --             return '自动攻击关【测试】'
        --         else
        --             -- auto('OnAttack')
        --             return '自动攻击开【测试】'
        --         end
        --         self:Close()

        --     end
        -- },
        -- 自动攻击
        -- {
        --     name = '自动拾取【测试】',
        --     fn = function()
        --         local success, result = pcall(function()
        --             -- auto('OnPick')
        --             self:Close()
        --         end)
        --         if not success then
        --             print("发生错误:", result)
        --         end
        --     end
        -- },
        -- 换断桩
        {
            name = '自动换断桩',
            fn = function()
                AutoSwap_mode = 1 - AutoSwap_mode;
                if AutoSwap_mode == 0 then 
                    AutoSwap:StopThread()
                    self:Close()
                else
                    AutoSwap:Fn()
                    self:Close()
                end
            end
        },
        {
            name = '自动读藏宝图',
            fn = function()
                AutoRead_mode = 1 - AutoRead_mode;
                if AutoRead_mode == 0 then 
                    AutoRead:StopPutThread()
                    self:Close()
                else
                    AutoRead:Fn()
                    self:Close()
                end
            end
        },
        {
            name = '小店监控',
            fn = function()
                Monitor_mode = 1 - Monitor_mode;
                if Monitor_mode == 0 then 
                    Monitor:StopPutThread()
                    self:Close()
                else
                    Monitor:Fn()
                    self:Close()
                end
            end
        },
        -- 关闭本对话框
        {
            name = '关闭',
            fn = function()
                self:Close()
            end
        },
    }

    -- 计算第一个按钮的垂直位置，为遮罩的顶端减去标题的大小，再留一些空白
    local top = TechBG_size_y / 2 - 70;
    -- 利用for循环添加按钮
    for i, setting in ipairs(button_settings) do
        -- 每个按钮的大小和留白大小为50，根据按钮是第几个计算垂直位置
        AddButton(setting.name, setting.fn, 0, top - (i - 1) * 50)
    end
    return mainwidget
end

-- 对话框的关闭函数
function TechWidget:Close()
    self:Hide()
    self.IsNoMuTechMenuShow = false
end

-- 对话框的控制函数，照抄即可
function TechWidget:OnControl(control, down)
    if TechWidget._base.OnControl(self, control, down) then
        return true
    end
    if not down then
        if control == CONTROL_PAUSE or control == CONTROL_CANCEL then
            self:Close()
        end
    end
    return true
end

-- 对话框接受输入时的函数，照抄即可
function TechWidget:OnRawKey(key, down)
    if TechWidget._base.OnRawKey(self, key, down) then
        return true
    end
end

-- 返回定义的类，这样在modmain.lua引用时，拿到的就是当前的类
return TechWidget