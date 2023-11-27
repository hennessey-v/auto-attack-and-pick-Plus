
local CalcUtil = {}

-- 获取两个实体的方向
function CalcUtil:GetDirection(source, target, dire)
    if dire == "left" or dire == "right" then
        local tmp = {x = target.x, z = target.z}
        target.x = source.z - tmp.z + source.x
        target.z = tmp.x - source.x + source.z
    end
    local numy = target.z - source.z
    local numx = target.x - source.x
    local absx = math.abs(numx)
    local absy = math.abs(numy)
    if absx == 0 and absy == 0 then
        return 0.5, 0.5
    end
    if absx > absy then
        numx = numx / absx
        numy = numy / absx
    else
        numx = numx / absy
        numy = numy / absy
    end
    if dire == "down" or dire == "right" then
        return -numx/2, -numy/2
    else
        return numx/2, numy/2
    end
end

-- 获取圆心与圆外一点的连线与圆的交点
function CalcUtil:GetIntersectPotRadiusPot(pot1, radius, pot2)
    local dx = pot2.x - pot1.x
    local dz = pot2.z - pot1.z
    local d = math.sqrt(dx*dx + dz*dz)
    if d == 0 then
        return pot1
    else
        return Vector3(pot1.x + dx * radius / d,0,pot1.z + dz * radius / d)
    end
end

-- 判断str是否包含item
function CalcUtil:IsStrContains(str, item)
    -- 将两个字符串都转换为小写，并去除空格
    str = string.lower(str):gsub("%s+", "")
    item = string.lower(item):gsub("%s+", "")
    -- 判断str是否包含item，返回布尔值
    return string.find(str, item) ~= nil
end

-- 获取两点间距离
function CalcUtil:GetDist(x1,y1,x2,y2)
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

return CalcUtil