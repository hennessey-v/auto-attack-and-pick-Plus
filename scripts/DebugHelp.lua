---------------------------------------------------
-------------------查错相关
---------------------------------------------------

local debughelper = {}

--这是打印可变参数
function debughelper:showPrintInfo(...)
    -- body
    print("开始打印结果")
    for k, v in ipairs({...}) do 
        local subString = ""
        if type(v) == "boolean" then
            subString = (v == true and "true" or "false")
        elseif type(v) == "number" then
            subString = tostring(v)
        elseif type(v) == "string" then
            subString = '"'..v..'"'
        elseif type(v) == "table" then
            self:printTable(v)
        else
            subString = "<数据是" .. type(v) .. "类型, 未处理类型>"
        end
        print(subString)
    end
end


--可以打印一个table
function debughelper:printTable ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if(type(pos) ~= "table") then
                        if (type(val)=="table") then
                            print(indent.."["..pos.."] => "..tostring(t).." {")
                            sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                            print(indent..string.rep(" ",string.len(pos)+6).."}")
                        elseif (type(val)=="string") then
                            print(indent.."["..pos..'] => "'..val..'"')
                        else
                            print(indent.."["..pos.."] => "..tostring(val))
                        end
                    else
                        print("key是个表")
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

return debughelper