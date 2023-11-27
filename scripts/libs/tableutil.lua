local t_util = {}

-- 获取容器items的第一个item
function t_util:GetMinValue(t)
    if type(t) ~= "table" then
        return
    end
    local min,_ = next(t)
    if min then
        for num,_ in pairs(t)do
            min = num < min and num or min
        end
        return t[min]
    end
end

-- 各项是json的List根据id转Map
function t_util:MapAndArrayFromJsonList(t)
    local map,array = {},{}
    for _,line in pairs(t) do
        local re, data = xpcall(
            function() return json.decode(line) end, 
            function() end
        )
        if re then
            local key = data.id
            if key then
                map[key] = t_util:MergeMap(data)
                map[key].id = nil
            else
                table.insert(array, data)
            end
        end
    end
    return map,array
end


-- List根据id转Map
function t_util:MapFromList(t, num)
    local m = {}
    for i, data in ipairs(t)do
        if type(num)=="number" and i > num then
            break
        end
        local key = data.id
        m[key] = self:MergeMap(data)
        m[key].id = nil
    end
    return m
end

-- 合并多个Map,或用于深拷贝
function t_util:MergeMap(...)
    local m = {}
    for _, map in pairs({...})do
        for key, value in pairs(map)do
            m[key] = value
        end
    end
    return m
end
function t_util:MergeList(...)
    local mTable = {}
    for _, v in pairs({...}) do
        if type(v) == "table" then
            for _, k in pairs(v) do
                table.insert(mTable, k)
            end
        end
    end
    return mTable
end

function t_util:GetChild(parent, childname)
    if type(parent) == "table" and type(parent.children) == "table" then
        for w in pairs(parent.children)do
            if tostring(w) == childname then
                return w
            end
        end
    end
end


function t_util:GetNextLoopKey(t, key)
    local loop_right,loop_temp,first
	for k,_ in pairs(t)do
		if not first then
			first = k
		end
		if loop_right then
			key = k
			loop_temp = true
			break
		elseif k == key then
			loop_right = true
		end
	end
	if not loop_temp then
		key = first
	end
    return key
end

-- 返回满足条件的某个元素的处理值
function t_util:GetElement(t, func)
    for k,v in pairs(t)do
        local result = func(k,v)
        if result then return result end
    end
end

function t_util:Pairs(t, func)
    for k,v in pairs(t)do
        func(k,v)
    end
end

function t_util:NumElement(num, t, func)
    for i = 1, num do
        local result = func(i, t[i])
        if result then return result end
    end
end

function t_util:PairNum(num, t, func)
    for i = 1, num do
        func(i, t[i])
    end
end


return t_util