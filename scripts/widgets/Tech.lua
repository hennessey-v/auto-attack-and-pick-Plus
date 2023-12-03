-- 下面4行从饥荒的源代码中引入界面开发需要的控件，包括图片、图片按钮、文本和窗口
local WidgetImage = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TIP = require "util/tip"
local auto = require "main/2"
local autoread = require "main/4"
local broccoli = require "main/5"

-- 新建一个名为NoMuTechWidget的窗口类，即我们所要显示的对话框
local TechWidget = Class(Widget, function(self)
    Widget._ctor(self, "TechWidget")
    -- 窗口是一个树形结构，先建立一个名为ROOT的窗口根节点，保存在类变量self.root中
    self.root = self:AddChild(Widget("ROOT"))
    -- 设置root垂直方向的锚点，ANCHOR_MIDDLE表示中心锚点，ANCHOR_TOP表示顶部锚点，ANCHOR_BOTTOM表示底部锚点
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    -- 设置root水平方向的锚点，ANCHOR_MIDDLE表示中心锚点，ANCHOR_LEFT表示左端锚点，ANCHOR_RIGHT表示右端锚点
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    -- 设置root的缩放模式，SCALEMODE_PROPORTIONAL表示根据窗口大小按比例缩放
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    -- 设置root的位置，在中心锚点的情况下，（0, 0, 0）表示居中显示
    self.root:SetPosition(0, 0, 0)
    -- 下面几行定义对话框背景（半透明黑遮罩）的位置和大小，可以根据按钮的数量和个人喜好调整位置和大小
    self.shield_pos_x = 0;
    self.shield_pos_y = 0;
    self.shield_size_x = 200;
    self.shield_size_y = 210;
    -- 遮罩为由images/ui.xml和black.tex描述的一张图片
    self.shield = self.root:AddChild(WidgetImage("images/ui.xml", "black.tex"))
    -- 下面几行设置遮罩的缩放尺度、位置、大小和透明度
    self.shield:SetScale(1, 1, 1)
    self.shield:SetPosition(self.shield_pos_x, self.shield_pos_y, 0)
    self.shield:SetSize(self.shield_size_x, self.shield_size_y)
    self.shield:SetTint(1, 1, 1, 0.6)

    --定义对话框的标题，即内容为“Tech”，字体为BODYTEXTFONT，大小为50的文本
    local title_text = self.shield:AddChild(Text(BODYTEXTFONT, 50, '设置'))
    -- 设置标题的位置，self.shield_size_y / 2为遮罩的顶端，我们这里做一个25大小的下偏移，给顶部留点空间
    title_text:SetPosition(0, self.shield_size_y / 2 - 25, 0)

    -- 由于添加按钮有一些共用的代码，我们这里写一个函数来添加按钮
    -- name为按钮的文本，click_fn为按钮点击后的响应函数，x和y为按钮的位置
    local function AddButton(name, click_fn, x, y)
        -- 按钮由一系列图片组成包括一般形态、鼠标悬停形态、鼠标点击形态、禁用形态等，这里使用饥荒现有的按钮样式
        local button = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        -- 调整一下按钮图片的大小
        button.image:SetScale(.7)
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
    local autoExchange_mode = 0;
    local autoRead_mode = 0;
    local broccoli_mode = 0;
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
                autoExchange_mode = 1 - autoExchange_mode;
                if autoExchange_mode == 0 then 
                    auto:StopThread()
                    self:Close()
                else
                    auto:Fn()
                    self:Close()
                end
            end
        },
        {
            name = '自动读藏宝图',
            fn = function()
                autoRead_mode = 1 - autoRead_mode;
                if autoRead_mode == 0 then 
                    autoread:StopPutThread()
                    self:Close()
                else
                    autoread:Fn()
                    self:Close()
                end
            end
        },
        {
            name = '小店监控',
            fn = function()
                broccoli_mode = 1 - broccoli_mode;
                if broccoli_mode == 0 then 
                    broccoli:StopPutThread()
                    self:Close()
                else
                    broccoli:Fn()
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
    local top = self.shield_size_y / 2 - 70;
    -- 利用for循环添加按钮
    for i, setting in ipairs(button_settings) do
        -- 每个按钮的大小和留白大小为50，根据按钮是第几个计算垂直位置
        AddButton(setting.name, setting.fn, 0, top - (i - 1) * 50)
    end
end)

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