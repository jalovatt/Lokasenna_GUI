------------------------------------
-------- Table functions -----------
------------------------------------


--[[	Copy the contents of one table to another, since Lua can't do it natively
	
	Provide a second table as 'base' to use it as the basis for copying, only
	bringing over keys from the source table that don't exist in the base
	
	'depth' only exists to provide indenting for my debug messages, it can
	be left out when calling the function.
]]--
GUI.table_copy = function (source, base, depth)
	
	-- 'Depth' is only for indenting debug messages
	depth = ((not not depth) and (depth + 1)) or 0
	
	
	
	if type(source) ~= "table" then return source end
	
	local meta = getmetatable(source)
	local new = base or {}
	for k, v in pairs(source) do
		

		
		if type(v) == "table" then
			
			if base then
				new[k] = GUI.table_copy(v, base[k], depth)
			else
				new[k] = GUI.table_copy(v, nil, depth)
			end
			
		else
			if not base or (base and new[k] == nil) then 

				new[k] = v
			end
		end
		
	end
	setmetatable(new, meta)
	
	return new
	
end


-- (For debugging)
-- Returns a string of the table's contents, indented to show nested tables
-- If 't' contains classes, or a lot of nested tables, etc, be wary of using larger
-- values for max_depth - this function will happily freeze Reaper for ten minutes.
GUI.table_list = function (t, max_depth, cur_depth)
    
    local ret = {}
    local n,v
    cur_depth = cur_depth or 0
    
    for n,v in pairs(t) do
                        
                ret[#ret+1] = string.rep("\t", cur_depth) .. n .. " = "
                
                if type(v) == "table" then
                    
                    ret[#ret] = ret[#ret] .. "table:"
                    if not max_depth or cur_depth <= max_depth then
                        ret[#ret+1] = GUI.table_list(v, max_depth, cur_depth + 1)
                    end
                
                else
                
                    ret[#ret] = ret[#ret] .. tostring(v)
                end

    end
    
    return table.concat(ret, "\n")
    
end


-- Compare the contents of one table to another, since Lua can't do it natively
-- Returns true if all of t_a's keys + and values match all of t_b's.
GUI.table_compare = function (t_a, t_b)
	
	if type(t_a) ~= "table" or type(t_b) ~= "table" then return false end
	
	local key_exists = {}
	for k1, v1 in pairs(t_a) do
		local v2 = t_b[k1]
		if v2 == nil or not GUI.table_compare(v1, v2) then return false end
		key_exists[k1] = true
	end
	for k2, v2 in pairs(t_b) do
		if not key_exists[k2] then return false end
	end
	
    return true
    
end


-- 	Sorting function adapted from: http://lua-users.org/wiki/SortedIteration
GUI.full_sort = function (op1, op2)

	-- Sort strings that begin with a number as if they were numbers,
	-- i.e. so that 12 > "6 apples"
	if type(op1) == "string" and string.match(op1, "^(%-?%d+)") then
		op1 = tonumber( string.match(op1, "^(%-?%d+)") )
	end
	if type(op2) == "string" and string.match(op2, "^(%-?%d+)") then
		op2 = tonumber( string.match(op2, "^(%-?%d+)") )
	end

	--if op1 == "0" then op1 = 0 end
	--if op2 == "0" then op2 = 0 end
	local type1, type2 = type(op1), type(op2)
	if type1 ~= type2 then --cmp by type
		return type1 < type2
	elseif type1 == "number" and type2 == "number"
		or type1 == "string" and type2 == "string" then
		return op1 < op2 --comp by default
	elseif type1 == "boolean" and type2 == "boolean" then
		return op1 == true
	else
		return tostring(op1) < tostring(op2) --cmp by address
	end
	
end


--[[	Allows "for x, y in pairs(z) do" in alphabetical/numerical order
    
	Copied from Programming In Lua, 19.3
	
	Call with f = "full" to use the full sorting function above, or
	use f to provide your own sorting function as per pairs() and ipairs()
	
]]--
GUI.kpairs = function (t, f)


	if f == "full" then
		f = GUI.full_sort
	end

	local a = {}
	for n in pairs(t) do table.insert(a, n) end

	table.sort(a, f)
	
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
	
		i = i + 1
		
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
		
	end
	
	
	return iter
end


-- Accepts a table, and returns a table with the keys and values swapped, i.e.
-- {a = 1, b = 2, c = 3} --> {1 = "a", 2 = "b", 3 = "c"}
GUI.table_invert = function(t)
    
    local tmp = {}
    
    for k, v in pairs(t) do
        tmp[v] = k
    end
    
    return tmp

end


-- Looks through a table using ipairs (specify a different function with 'f') and returns
-- the first key whose value matches 'find'. 'find' is checked using string.match, so patterns
-- should be allowable. No (captures) though.

-- If you need to find multiple values in the same table, and each of them only occurs once, 
-- it will be more efficient to just copy the table with GUI.table_invert and check by key.
GUI.table_find = function(t, find, f)      
    local iter = f or ipairs
    
    for k, v in iter(t) do
        if string.match(tostring(v), find) then return k end
    end
    
end


-- Returns the length of a table, counting both indexed and keyed elements
GUI.table_length = function(t)

    local len = 0
    for k in pairs(t) do
        len = len + 1
    end
    
    return len

end
