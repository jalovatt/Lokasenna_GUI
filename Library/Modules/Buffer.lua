
------------------------------------
-------- Buffer functions ----------
------------------------------------


--[[
	We'll use this to let elements have their own graphics buffers
	to do whatever they want in. 
	
	num	=	How many buffers you want, or 1 if not specified.
	
	Returns a table of buffers, or just a buffer number if num = 1
	
	i.e.
	
	-- Assign this element's buffer
	function GUI.my_element:new(.......)
	
	   ...new stuff...
	   
	   my_element.buffers = GUI.get_buffer(4)
	   -- or
	   my_element.buffer = GUI.get_buffer()
		
	end
	
	-- Draw to the buffer
	function GUI.my_element:init()
		
		gfx.dest = self.buffers[1]
		-- or
		gfx.dest = self.buffer
		...draw stuff...
	
	end
	
	-- Copy from the buffer
	function GUI.my_element:draw()
		gfx.blit(self.buffers[1], 1, 0)
		-- or
		gfx.blit(self.buffer, 1, 0)
	end
	
]]--

-- Any used buffers will be marked as True here
GUI.buffers = {}

-- When deleting elements, their buffer numbers
-- will be added here for easy access.
GUI.freed_buffers = {}

GUI.get_buffer = function (num)
	
	local ret = {}
	local prev
	
	for i = 1, (num or 1) do
		
		if #GUI.freed_buffers > 0 then
			
			ret[i] = table.remove(GUI.freed_buffers)
			
		else
		
			for j = (not prev and 1023 or prev - 1), 0, -1 do
			
				if not GUI.buffers[j] then
					ret[i] = j
					GUI.buffers[j] = true
					break
				end
				
			end
			
		end
		
	end

	return (#ret == 1) and ret[1] or ret

end

-- Elements should pass their buffer (or buffer table) to this
-- when being deleted
GUI.free_buffer = function (num)
	
	if type(num) == "number" then
		table.insert(GUI.freed_buffers, num)
	else
		for k, v in pairs(num) do
			table.insert(GUI.freed_buffers, v)
		end
	end	
	
end



