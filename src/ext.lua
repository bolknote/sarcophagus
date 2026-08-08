-- LUA simple extentions
function string.split (str, sep)
local tbl = {}
local tbl2 = {}
str = tostring (str)
   str:gsub(sep, function(x) tbl[#tbl+1]=x end)
   for i,v in ipairs(tbl) do
		if v~="" then
			table.insert (tbl2,v)
		end
   end
   return tbl2
end


function table.inserts (a,b)
	for k,v in pairs(b) do
		table.insert(a,v)
	end
end

function table.shuffle (tInput)
    local tReturn = {}
    for i = #tInput, 1, -1 do
        local j = love.math.random(i)
        tInput[i], tInput[j] = tInput[j], tInput[i]
        table.insert(tReturn, tInput[i])
    end
    return tReturn
end


function tablecount (table)

	if table==nil then return nil end
	local cnt = 0

	for k,v in pairs(table) do
		cnt = cnt + 1
	end

	return cnt
end


function cleartable (table)

	for k,v in pairs(table) do
		table[k] = nil
	end

end

function tablecopy (table, a)

	if table==nil then return nil end

	local a = a or {}

	for k,v in pairs(table) do
		a[k] = v
	end

	return a
end

function tabledeepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[tabledeepcopy(orig_key)] = tabledeepcopy(orig_value)
        end
        setmetatable(copy, tabledeepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function in_array(a,x)
	if a==nil then return nil end
	for k,v in pairs(a) do
		if v==x then return k end
	end
	return nil
end

function in_array_i(a,x)
	if a==nil then return nil end
	for k,v in pairs(a) do
		if v.i==x then return k end
	end
	return nil
end

function array_reset(a)
	local n = {}
	for k,v in pairs(a) do
		table.insert (n,v)
	end
	return n
end

function array_len (a)
	local l = 0
	for k,v in pairs(a) do
		l = l + 1
	end
	return l
end


function log (str,clear)
	
	str = dumpvar(str)
	if clear then
		love.filesystem.write ('log.txt', '')
	else
		love.filesystem.append ('log.txt', str)
	end
end


function dumpvar(data)
	-- cache of tables already printed, to avoid infinite recursive loops
	local tablecache = {}
	local buffer = ""
	local padder = "    "
	
	local function _dumpvar(d, depth)
		local t = type(d)
		local str = tostring(d)
		if (t == "table") then
			if (tablecache[str]) then
				-- table already dumped before, so we dont
				-- dump it again, just mention it
				buffer = buffer.."<"..str..">\n"
			else
				tablecache[str] = (tablecache[str] or 0) + 1
				buffer = buffer.."("..str..") {\n"
				for k, v in pairs(d) do
					buffer = buffer..string.rep(padder, depth+1).."["..k.."] => "
					_dumpvar(v, depth+1)
				end
				buffer = buffer..string.rep(padder, depth).."}\n"
			end
			elseif (t == "number") then
				buffer = buffer..str.."\n"
			else
				buffer = buffer.." \""..str.."\"\n"
			end
		end
		_dumpvar(data, 0)
		return buffer
	end



	function dump(o)
		print (dumpvar(o))	
	end


	function math.dist (x1,y1,x2,y2) 
		return ((x2-x1)^2+(y2-y1)^2)^0.5 
	end