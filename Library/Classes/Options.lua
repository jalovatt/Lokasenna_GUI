--[[	Lokasenna_GUI - Options classes
	
    This file provides two separate element classes:
    
    Radio       A list of options from which the user can only choose one at a time.
    Checklist   A list of options from which the user can choose any, all or none.
    
    Both classes take the same parameters on creation, and offer the same parameters
    afterward - their usage only differs when it comes to their respective :val methods.
    
    For documentation, see the class pages on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Checklist
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Radio
    
    Creation parameters:
	name, z, x, y, w, h, caption, opts[, dir, pad]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


local Option = GUI.Element:new()

function Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
	local option = (not x and type(z) == "table") and z or {}
	
	option.name = name
	option.type = "Option"
	
	option.z = option.z or z

	option.x = option.x or x
    option.y = option.y or y
    option.w = option.w or w
    option.h = option.h or h

	option.caption = option.caption or caption

    if option.frame == nil then
        option.frame = true
    end
	option.bg = option.bg or "wnd_bg"
    
	option.dir = option.dir or dir or "v"
	option.pad = option.pad or pad or 4
        
	option.col_txt = option.col_txt or "txt"
	option.col_fill = option.col_fill or "elm_fill"

	option.font_a = option.font_a or 2
	option.font_b = option.font_b or 3
	
    if option.shadow == nil then
        option.shadow = true
    end
	
    if option.shadow == nil then
        option.swap = false
    end
    
	-- Size of the option bubbles
	option.opt_size = option.opt_size or 20
	
	-- Parse the string of options into a table
    if not option.opt_array then
        option.opt_array = {}
        
        local opts = option.opts or opts
        
        if type(opts) == "table" then
            
            for i = 1, #opts do
                option.opt_array[i] = opts[i]
            end
            
        else
        
            local tempidx = 1
            for word in string.gmatch(opts, '([^,]*)') do
                option.opt_array[tempidx] = word
                tempidx = tempidx + 1
            end
            
        end
    end

	GUI.redraw_z(option.z)

	setmetatable(option, self)
    self.__index = self 
    return option
    
end


function Option:init()
	
    -- Make sure we're not trying to use the base class.
    if self.type == "Option" then
        reaper.ShowMessageBox(  "'"..self.name.."' was initialized as an Option element,"..
                                "but Option doesn't do anything on its own!",
                                "GUI Error", 0)
        
        GUI.quit = true
        return
        
    end
        
	self.buff = self.buff or GUI.get_buffer()
		
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*self.opt_size + 4, 2*self.opt_size + 2)
	
    
    self:init_options()
	
    
	if self.caption and self.caption ~= "" then
		GUI.set_font(self.font_a)		
		local str_w, str_h = gfx.measurestr(self.caption)
		self.cap_h = 0.5*str_h
		self.cap_x = self.x + (self.w - str_w) / 2	
	else
		self.cap_h = 0
		self.cap_x = 0
	end
	
end


function Option:draw()
	
	if self.frame then
		GUI.set_color("elm_frame")
		gfx.rect(self.x, self.y, self.w, self.h, 0)
	end

    if self.caption and self.caption ~= "" then self:draw_caption() end

    self:draw_options()

end




------------------------------------
-------- Input helpers -------------
------------------------------------




function Option:get_mouse_opt()
    
    local len = #self.opt_array
    
	-- See which option it's on
	local mouse_opt = self.dir == "h" 	
                    and (GUI.mouse.x - (self.x + self.pad))
					or	(GUI.mouse.y - (self.y + self.cap_h + 1.5*self.pad) )
                    
	mouse_opt = mouse_opt / ((self.opt_size + self.pad) * len)
	mouse_opt = GUI.clamp( math.floor(mouse_opt * len) + 1 , 1, len )

    return self.opt_array[mouse_opt] ~= "_" and mouse_opt or false
    
end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Option:draw_caption()
    
    GUI.set_font(self.font_a)
    
    gfx.x = self.cap_x
    gfx.y = self.y - self.cap_h
    
    GUI.txt_bg(self.caption, self.bg)
    
    GUI.txt_shadow(self.caption, self.col_txt, "shadow")
    
end


function Option:draw_options()

    local x, y, w, h = self.x, self.y, self.w, self.h
    
    local horz = self.dir == "h"
	local pad = self.pad
    
    -- Bump everything down for the caption
    y = y + ((self.caption and self.caption ~= "") and self.cap_h or 0) + 1.5 * pad 

    -- Bump the options down more for horizontal options
    -- with the text on top
	if horz and self.caption ~= "" and not self.swap then
        y = y + self.cap_h + 2*pad 
    end

	local opt_size = self.opt_size
    
    local adj = opt_size + pad

    local str, opt_x, opt_y

	for i = 1, #self.opt_array do
	
		str = self.opt_array[i]
		if str ~= "_" then
		        
            opt_x = x + (horz   and (i - 1) * adj + pad
                                or  (self.swap  and (w - adj - 1) 
                                                or   pad))
                                                
            opt_y = y + (i - 1) * (horz and 0 or adj)
                
			-- Draw the option bubble
            self:draw_option(opt_x, opt_y, opt_size, self:opt_selected(i))

            self:draw_value(opt_x,opt_y, opt_size, str)
            
		end
		
	end
	
end


function Option:draw_option(opt_x, opt_y, size, selected)
    
    gfx.blit(   self.buff, 1,  0,  
                selected and (size + 3) or 1, 1, 
                size + 1, size + 1, 
                opt_x, opt_y)

end


function Option:draw_value(opt_x, opt_y, size, str)

    if not str or str == "" then return end
    
	GUI.set_font(self.font_b) 
    
    local str_w, str_h = gfx.measurestr(str)
    
    if self.dir == "h" then
        
        gfx.x = opt_x + (size - str_w) / 2
        gfx.y = opt_y + (self.swap and (size + 4) or -size)

    else
    
        gfx.x = opt_x + (self.swap and -(str_w + 8) or 1.5*size)
        gfx.y = opt_y + (size - str_h) / 2
        
    end

    GUI.txt_bg(str, self.bg)
    if #self.opt_array == 1 or self.shadow then
        GUI.txt_shadow(str, self.col_txt, "shadow")
    else
        GUI.set_color(self.col_txt)
        gfx.drawstr(str)
    end

end




------------------------------------
-------- Radio methods -------------
------------------------------------


GUI.Radio = {}
setmetatable(GUI.Radio, {__index = Option})

function GUI.Radio:new(name, z, x, y, w, h, caption, opts, dir, pad)

    local radio = Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
    radio.type = "Radio"
    
    radio.retval, radio.state = 1, 1
    
    setmetatable(radio, self)
    self.__index = self
    return radio
    
end


function GUI.Radio:init_options()

	local r = self.opt_size / 2

	-- Option bubble
	GUI.set_color(self.bg)
	gfx.circle(r + 1, r + 1, r + 2, 1, 0)
	gfx.circle(3*r + 3, r + 1, r + 2, 1, 0)
	GUI.set_color("elm_frame")
	gfx.circle(r + 1, r + 1, r, 0)
	gfx.circle(3*r + 3, r + 1, r, 0)
	GUI.set_color(self.col_fill)
	gfx.circle(3*r + 3, r + 1, 0.5*r, 1)


end


function GUI.Radio:val(newval)
	
	if newval then
		self.retval = newval
		self.state = newval
		self:redraw()		
	else
		return self.retval
	end	
	
end


function GUI.Radio:on_mouse_down()
	
	self.state = self:get_mouse_opt() or self.state

	self:redraw()

end


function GUI.Radio:on_mouse_up()
	
    -- Bypass option for GUI Builder
    if not self.focus then
        self:redraw()
        return
    end
	
	-- Set the new option, or revert to the original if the cursor 
    -- isn't inside the list anymore
	if GUI.is_inside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval	
	end

    self.focus = false
	self:redraw()

end


function GUI.Radio:on_drag() 

	self:on_mouse_down()

	self:redraw()

end


function GUI.Radio:on_wheel()
--[[
	state = GUI.round(self.state +     (self.dir == "h" and 1 or -1) 
                                    *   GUI.mouse.inc)
]]--                             

    self.state = self:get_next_option(  GUI.xor( GUI.mouse.inc > 0, self.dir == "h" ) 
                                        and -1 
                                        or 1 )

	--if self.state < 1 then self.state = 1 end
	--if self.state > #self.opt_array then self.state = #self.opt_array end

	self.retval = self.state

	self:redraw()

end


function GUI.Radio:opt_selected(opt)
    
   return opt == self.state 
    
end


function GUI.Radio:get_next_option(dir)
   
    local j = dir > 0 and #self.opt_array or 1
   
    for i = self.state + dir, j, dir do
       
        if self.opt_array[i] ~= "_" then
            return i
        end
       
    end
    
    return self.state
    
end




------------------------------------
-------- Checklist methods ---------
------------------------------------


GUI.Checklist = {}
setmetatable(GUI.Checklist, {__index = Option})

function GUI.Checklist:new(name, z, x, y, w, h, caption, opts, dir, pad)

    local checklist = Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
    checklist.type = "Checklist"
    
    checklist.opt_sel = {}
    
    setmetatable(checklist, self)
    self.__index = self
    return checklist
    
end


function GUI.Checklist:init_options()

	local size = self.opt_size

	-- Option bubble
	GUI.set_color("elm_frame")
	gfx.rect(1, 1, size, size, 0)
    gfx.rect(size + 3, 1, size, size, 0)
	
	GUI.set_color(self.col_fill)
	gfx.rect(size + 3 + 0.25*size, 1 + 0.25*size, 0.5*size, 0.5*size, 1)

end


function GUI.Checklist:val(newval)
      
	if newval then
		if type(newval) == "table" then
			for k, v in pairs(newval) do
				self.opt_sel[tonumber(k)] = v
			end
			self:redraw()
        elseif type(newval) == "boolean" and #self.opt_array == 1 then
        
            self.opt_sel[1] = newval
            self:redraw()
		end
	else
        if #self.opt_array == 1 then
            return self.opt_sel[1]
        else
            local tmp = {}
            for i = 1, #self.opt_array do
                tmp[i] = not not self.opt_sel[i]
            end
            return tmp            
        end
		--return #self.opt_array > 1 and self.opt_sel or self.opt_sel[1]
	end
	
end


function GUI.Checklist:on_mouse_up()
    
    -- Bypass option for GUI Builder
    if not self.focus then
        self:redraw()
        return
    end

    local mouse_opt = self:get_mouse_opt()
	
    if not mouse_opt then return end
    
	self.opt_sel[mouse_opt] = not self.opt_sel[mouse_opt] 

    self.focus = false
	self:redraw()

end


function GUI.Checklist:opt_selected(opt)
   
   return self.opt_sel[opt]
    
end