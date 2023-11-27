local t_util = require "libs/tableutil"
local c_util = require "libs/calcutil"
local EntUtil = {}

-- 是否有效
function EntUtil:IsValid(ent)
    return type(ent)=="table" and ent.Transform and ent.entity and ent.prefab and ent:IsValid()
end

-- 是否为有效区域(不是在海上或虚空)
function EntUtil:InValidPos(ent)
    if self:IsValid(ent) then
        if TheWorld:HasTag("cave") then
            return ent:IsOnValidGround()
        else
            -- 船上也有效
            return ent:IsOnValidGround() or not ent:IsOnOcean(false)
        end
    end
end

-- 获取客户端容器
function EntUtil:GetContainer(ent)
    if ent and ent.replica then
        return ent.replica.container or ent.replica.inventory
    end
end


-- 获取堆叠数量
function EntUtil:GetStacksize(ent)
    if ent and ent.replica and ent.replica.stackable then
        return ent.replica.stackable:StackSize()
    end
    return 1
end
function EntUtil:GetMaxSize(ent)
    if ent and ent.replica and ent.replica.stackable then
        return ent.replica.stackable:MaxSize()
    end
    return 1
end

-- 获取atlas和image
function EntUtil:GetAtlasAndImage(ent)
    local item = ent and ent.replica and ent.replica.inventoryitem
    if item then
        return item:GetAtlas(), item:GetImage()
    end
end

-- 获取耐久
function EntUtil:GetPercent(inst)
    local i = 100
    local classified = type(inst)=="table" and inst.replica and inst.replica.inventoryitem and inst.replica.inventoryitem.classified
    if classified then
        if inst:HasOneOfTags({"fresh", "show_spoilage"}) and classified.perish then
            i = math.floor(classified.perish:value() / 0.62)
        elseif classified.percentused then
            i = classified.percentused:value()
        end
    end
    return i
end


-- 获取客户端标签
function EntUtil:GetTags(ent)
    local debugstring = ent and ent:GetDebugString()
    if type(debugstring)=="string" then
        local tags_string = debugstring:match("Tags:(.-)\n")
        return tags_string and tags_string:split(" ") or {}
    end
    return {}
end

-- 获取组件实体
function EntUtil:ClonePrefab(prefab)
    if type(prefab) ~= "string" then
        return
    end
    if not MOD_ShroomCake.PrefabCopy then
        MOD_ShroomCake.PrefabCopy = {}
    end
    if not MOD_ShroomCake.PrefabCopy[prefab] then
        MOD_ShroomCake.PrefabCopy[prefab] = {
            components = {},
            prefab = prefab,
            tags = {}
        }
        -- if not table.contains(klei_not_prefabs, prefab) then
            local IsMasterSim = TheWorld.ismastersim
            MOD_SRC_LOCK = true
            getmetatable(TheWorld).GetPocketDimensionContainer = getmetatable(TheWorld).GetPocketDimensionContainer or function()end
            TheWorld.ismastersim = true
            local prefab_copy = SpawnPrefab(prefab)
            local comes = prefab_copy and prefab_copy.components
            if type(comes)=="table" then
                for k,v in pairs(comes)do
                    MOD_ShroomCake.PrefabCopy[prefab].components[k] = v
                end
            end
            MOD_ShroomCake.PrefabCopy[prefab].tags = self:GetTags(prefab_copy)
            if prefab_copy then
                prefab_copy:Remove()
            end
            TheWorld.ismastersim = IsMasterSim
            MOD_SRC_LOCK = false
        -- 为了保证其他mod不崩溃，只能牺牲你了！
        -- else
        --     if prefab == "magician_chest" then
        --         MOD_ShroomCake.PrefabCopy[prefab] = {
        --             components = {
        --                 container = { numslots = 12 },
        --             },
        --             tags = {"spoiler"},
        --             prefab = prefab,
        --         }
        --     end
        -- end
    end
    return MOD_ShroomCake.PrefabCopy[prefab]
end

-- 实体是否是动画之一
function EntUtil:IsAnim(anim, ent)
    if self:IsValid(ent) and ent.AnimState then
        local t = type(anim)
        if t == "table" then
            for _,anim_str in ipairs(anim)do
                if ent.AnimState:IsCurrentAnimation(anim_str) then
                    return true
                end
            end
        elseif t == "string" then
            return ent.AnimState:IsCurrentAnimation(anim)
        end
    end
end

-- 获取附近目标实体
function EntUtil:FindEnts(core_ent, prefab, range, allowTags, banTags, allowAnims, banAnims, func)
    local pos = type(core_ent) == "table" and core_ent.x and core_ent.z and core_ent
    if not pos then
        local core = self:IsValid(core_ent) and core_ent or ThePlayer
        pos = core and core:GetPosition()
    end
    if not pos then return end
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 
        type(range) == "number" and range or 80, 
        type(allowTags) == "table" and allowTags or nil, 
        type(banTags) == "table" and banTags or {'FX','DECOR','INLIMBO','NOCLICK', 'player'}
    )
    local r_ents = {}
    for _,ent in ipairs(ents)do
        if (not prefab or prefab == ent.prefab or (type(prefab)=="table" and table.contains(prefab, ent.prefab)))
        and (not allowAnims or self:IsAnim(allowAnims, ent))
        and (banAnims and not self:IsAnim(banAnims, ent) or not self:IsAnim("death", ent))
        and (not func or func(ent))
        then
            table.insert(r_ents, ent)
        end
    end
    return r_ents
end

-- 获取最近目标实体
function EntUtil:FindEnt(core_ent, prefab, range, allowTags, banTags, allowAnims, banAnims, func)
    local pos = type(core_ent) == "table" and core_ent.x and core_ent.z and core_ent
    if not pos then
        local core = self:IsValid(core_ent) and core_ent or ThePlayer
        pos = core and core:GetPosition()
    end
    if not pos then return end
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 
        type(range) == "number" and range or 80, 
        type(allowTags) == "table" and allowTags or nil, 
        type(banTags) == "table" and banTags or {'FX','DECOR','INLIMBO','NOCLICK', 'player'}
    )
    for _,ent in ipairs(ents)do
        if (not prefab or prefab == ent.prefab or (type(prefab)=="table" and table.contains(prefab, ent.prefab)))
        and (not allowAnims or self:IsAnim(allowAnims, ent))
        and (banAnims and not self:IsAnim(banAnims, ent) or not self:IsAnim("death", ent))
        and (not func or func(ent))
        then
            return ent
        end
    end
end

-- ent绑定事件
function EntUtil:SetBindEvent(ent, eventname, func)
    if not self:IsValid(ent) then return end
    ent:RemoveEventCallback(eventname, func)
    ent:ListenForEvent(eventname, func)
end

-- 获取实体动画
function EntUtil:GetAnim(ent)
    local tags_string = self:IsValid(ent) and ent:GetDebugString()
    return tags_string and tags_string:match(" anim: (.-) anim/")
end

-- 获取距离
function EntUtil:GetDist(e1, e2)
    if not self:IsValid(e2) then
        e2 = ThePlayer
    end
    if self:IsValid(e1) and self:IsValid(e2) then
        local p1 = e1:GetPosition()
        local p2 = e2:GetPosition()
        return c_util:GetDist(p1.x, p1.z, p2.x, p2.z)
    end
end

-- 在游戏中
function EntUtil:InGame()
    return ThePlayer and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus()
end


-- prefab获取名字
function EntUtil:GetPrefabName(prefab, ent)
    if not prefab then
        return "未知实体"
    end
    local name = STRINGS.NAMES[prefab:upper()]
    if ent then
        name = name or ent:GetBasicDisplayName()
        name = name == "MISSING NAME" and prefab or name
    end
	return name
end

return EntUtil