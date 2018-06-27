------------------------------------
-------- Prototype element ---------
----- + all default methods --------
------------------------------------


--[[
	All classes will use this as their template, so that
	elements are initialized with every method available.
]]--
GUI.Element = {}
function GUI.Element:new(name)
	
	local elm = {}
	if name then elm.name = name end
    self.z = 1
	
	setmetatable(elm, self)
	self.__index = self
	return elm
	
end

-- Called a) when the script window is first opened
-- 		  b) when any element is created via GUI.new after that
-- i.e. Elements can draw themselves to a buffer once on :init()
-- and then just blit/rotate/etc as needed afterward
function GUI.Element:init() end

-- Called whenever the element's z layer is told to redraw
function GUI.Element:draw() end

-- Ask for a redraw on the next update
function GUI.Element:redraw()
    GUI.redraw_z(self.z)
end

-- Called on every update loop, unless the element is hidden or frozen
function GUI.Element:on_update() end

function GUI.Element:delete()
    
    self.on_delete(self)
    GUI.elms[self.name] = nil
    
end

-- Called when the element is deleted by GUI.update_elms_list() or :delete.
-- Use it for freeing up buffers and anything else memorywise that this
-- element was doing
function GUI.Element:on_delete() end


-- Set or return the element's value
-- Can be useful for something like a Slider that doesn't have the same
-- value internally as what it's displaying
function GUI.Element:val() end

-- Called on every update loop if the mouse is over this element.
function GUI.Element:on_mouseover() end

-- Only called once; won't repeat if the button is held
function GUI.Element:on_mouse_down() end

function GUI.Element:on_mouse_up() end
function GUI.Element:on_double_click() end

-- Will continue being called even if you drag outside the element
function GUI.Element:on_drag() end

-- Right-click
function GUI.Element:on_r_mouse_down() end
function GUI.Element:on_r_mouse_up() end
function GUI.Element:on_r_doubleclick() end
function GUI.Element:on_r_drag() end

-- Middle-click
function GUI.Element:on_mouse_m_down() end
function GUI.Element:on_m_mouse_up() end
function GUI.Element:on_m_doubleclick() end
function GUI.Element:on_m_drag() end

function GUI.Element:on_wheel() end
function GUI.Element:on_type() end


-- Elements like a Textbox that need to keep track of their focus
-- state will use this to e.g. update the text somewhere else 
-- when the user clicks out of the box.
function GUI.Element:lost_focus() end

-- Called when the script window has been resized
function GUI.Element:on_resize() end


-- Returns the specified parameters for a given element.
-- If nothing is specified, returns all of the element's properties.
-- ex. local str = GUI.elms.my_element:Msg("x", "y", "caption", "col_txt")
function GUI.Element:Msg(...)
    
    local arg = {...}
    
    if #arg == 0 then
        arg = {}
        for k in GUI.kpairs(self, "full") do
            arg[#arg+1] = k
        end
    end    
    
    if not self or not self.type then return end
    local pre = tostring(self.name) .. "."
    local strs = {}
    
    for i = 1, #arg do
        
        strs[#strs + 1] = pre .. tostring(arg[i]) .. " = "
        
        if type(self[arg[i]]) == "table" then 
            strs[#strs] = strs[#strs] .. "table:"
            strs[#strs + 1] = GUI.table_list(self[arg[i]], nil, 1)
        else
            strs[#strs] = strs[#strs] .. tostring(self[arg[i]])
        end
        
    end
    
    --reaper.ShowConsoleMsg( "\n" .. table.concat(strs, "\n") .. "\n")
    return table.concat(strs, "\n")
    
end




------------------------------------
-------- Element helpers -----------
------------------------------------


-- Are these coordinates inside the given element?
-- If no coords are given, will use the mouse cursor
GUI.is_inside = function (elm, x, y)

	if not elm then return false end

	local x, y = x or GUI.mouse.x, y or GUI.mouse.y

	return	(	x >= (elm.x or 0) and x < ((elm.x or 0) + (elm.w or 0)) and 
				y >= (elm.y or 0) and y < ((elm.y or 0) + (elm.h or 0))	)
	
end


-- Returns the x,y that would center elm1 within elm2. 
-- Axis can be "x", "y", or "xy".
GUI.center = function (elm1, elm2)
    
    local elm2 = elm2   and elm2
                        or  {x = 0, y = 0, w = GUI.wnd.cur_w, h = GUI.wnd.cur_h}
    
    if not (    elm2.x and elm2.y and elm2.w and elm2.h
            and elm1.x and elm1.y and elm1.w and elm1.h) then return end
            
    return (elm2.x + (elm2.w - elm1.w) / 2), (elm2.y + (elm2.h - elm1.h) / 2)
    
    
end


-- Tab forward (or backward, if Shift is down) to the next element with .tab_idx = number.
-- Removes focus from the given element, and gives it to the new element.
function GUI.tab_to_next(elm)
    
    if not elm.tab_idx then return end
    
    local inc = (GUI.mouse.cap & 8 == 8) and -1 or 1
    
    -- Get a list of all tab_idx elements, and a list of tab_idxs
    local indices, elms = {}, {}
    for _, element in pairs(GUI.elms) do
        if element.tab_idx then 
            elms[element.tab_idx] = element
            indices[#indices+1] = element.tab_idx        
        end
    end
    
    -- This is the only element with a tab index
    if #indices == 1 then return end
    
    -- Find the next element in the appropriate direction
    table.sort(indices)
    
    local new
    local cur = GUI.table_find(indices, elm.tab_idx)
    
    if cur == 1 and inc == -1 then
        new = #indices
    elseif cur == #indices and inc == 1 then
        new = 1
    else
        new = cur + inc    
    end
    
    -- Move the focus
    elm.focus = false
    elm:lost_focus()
    elm:redraw()
    
    -- Can't set focus until the next GUI loop or Update will have problems
    GUI.new_focused_elm = elms[indices[new]]
    elms[indices[new]]:redraw()

end
