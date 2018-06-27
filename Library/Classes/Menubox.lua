--[[	Lokasenna_GUI - MenuBox class
	
    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Menubox
    
    Creation parameters:
	name, z, x, y, w, h, caption, opts[, pad, no_arrow]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


GUI.Menubox = GUI.Element:new()
function GUI.Menubox:new(name, z, x, y, w, h, caption, opts, pad, no_arrow)
	
	local menu = (not x and type(z) == "table") and z or {}
	
	menu.name = name
	menu.type = "Menubox"
	
	menu.z = menu.z or z

	
	menu.x = menu.x or x
    menu.y = menu.y or y
    menu.w = menu.w or w
    menu.h = menu.h or h

	menu.caption = menu.caption or caption
	menu.bg = menu.bg or "wnd_bg"
	
	menu.font_a = menu.font_a or 3
	menu.font_b = menu.font_b or 4
	
	menu.col_cap = menu.col_cap or "txt"
	menu.col_txt = menu.col_txt or "txt"
	
	menu.pad = menu.pad or pad or 4
    
    if menu.no_arrow == nil then
        
        menu.no_arrow = no_arrow or false
        
    end
    menu.align = menu.align or 0
		
	menu.retval = menu.retval or 1

    local opts = menu.opts or opts
    
    if type(opts) == "string" then
        -- Parse the string of options into a table
        menu.opt_array = {}

        for word in string.gmatch(opts, '([^,]+)') do
            menu.opt_array[#menu.opt_array+1] = word
        end
    elseif type(opts) == "table" then
        menu.opt_array = opts
    end

	GUI.redraw_z(menu.z)

	setmetatable(menu, self)
    self.__index = self 
    return menu
	
end


function GUI.Menubox:init()
	
	local w, h = self.w, self.h
	
	self.buff = GUI.get_buffer()
	
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*w + 4, 2*h + 4)
	
    self:draw_frame()
    
    if not self.no_arrow then self:draw_arrow() end

end


function GUI.Menubox:draw()	
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
	local caption = self.caption
	local focus = self.focus
	

	-- Draw the caption
	if caption and caption ~= "" then self:draw_caption() end
	
    
    -- Blit the shadow + frame
	for i = 1, GUI.shadow_dist do
		gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)	
	end
	
	gfx.blit(self.buff, 1, 0, 0, (focus and (h + 2) or 0) , w + 2, h + 2, x - 1, y - 1) 	
	

    -- Draw the text
    self:draw_text()
	
end


function GUI.Menubox:val(newval)
	
	if newval then
		self.retval = newval
		self:redraw()		
	else
		return math.floor(self.retval), self.opt_array[self.retval]
	end
	
end


------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.Menubox:on_mouse_up()

    GUI.Msg(self.name .. ": mouse up")
    -- Bypass option for GUI Builder
    if not self.focus then
        GUI.Msg("not focused, skipping out")
        self:redraw()
        return
    end
    
	-- The menu doesn't count separators in the returned number,
	-- so we'll do it here
	local menu_str, sep_arr = self:prep_menu()
	
	gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y	
	local cur_opt = gfx.showmenu(menu_str)
	
	if #sep_arr > 0 then cur_opt = self:strip_seps(cur_opt, sep_arr) end	
	if cur_opt ~= 0 then self.retval = cur_opt end

	self.focus = false
	self:redraw()	
    
end


-- This is only so that the box will light up
function GUI.Menubox:on_mouse_down()
	self:redraw()
end


function GUI.Menubox:on_wheel()
	
	-- Avert a crash if there aren't at least two items in the menu
	--if not self.opt_array[2] then return end	
	
	-- Check for illegal values, separators, and submenus
    self.retval = self:validate_option( GUI.round(self.retval - GUI.mouse.inc),
                                        GUI.round((GUI.mouse.inc > 0) and 1 or -1) )

	self:redraw()	
    
end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function GUI.Menubox:draw_frame()

    local x, y, w, h = self.x, self.y, self.w, self.h
	local r, g, b, a = table.unpack(GUI.colors["shadow"])
	gfx.set(r, g, b, 1)
	gfx.rect(w + 3, 1, w, h, 1)
	gfx.muladdrect(w + 3, 1, w + 2, h + 2, 1, 1, 1, a, 0, 0, 0, 0 )
	
	GUI.set_color("elm_bg")
	gfx.rect(1, 1, w, h)
	gfx.rect(1, w + 3, w, h)
	
	GUI.set_color("elm_frame")
	gfx.rect(1, 1, w, h, 0)
	if not self.no_arrow then gfx.rect(1 + w - h, 1, h, h, 1) end
	
	GUI.set_color("elm_fill")
	gfx.rect(1, h + 3, w, h, 0)
	gfx.rect(2, h + 4, w - 2, h - 2, 0)

end


function GUI.Menubox:draw_arrow()

    local x, y, w, h = self.x, self.y, self.w, self.h
    gfx.rect(1 + w - h, h + 3, h, h, 1)

    GUI.set_color("elm_bg")
    
    -- Triangle size
    local r = 5
    local rh = 2 * r / 5
    
    local ox = (1 + w - h) + h / 2
    local oy = 1 + h / 2 - (r / 2)

    local Ax, Ay = GUI.polar_to_cart(1/2, r, ox, oy)
    local Bx, By = GUI.polar_to_cart(0, r, ox, oy)
    local Cx, Cy = GUI.polar_to_cart(1, r, ox, oy)
    
    GUI.triangle(true, Ax, Ay, Bx, By, Cx, Cy)
    
    oy = oy + h + 2
    
    Ax, Ay = GUI.polar_to_cart(1/2, r, ox, oy)
    Bx, By = GUI.polar_to_cart(0, r, ox, oy)
    Cx, Cy = GUI.polar_to_cart(1, r, ox, oy)	
    
    GUI.triangle(true, Ax, Ay, Bx, By, Cx, Cy)	    
    
end


function GUI.Menubox:draw_caption()
 
    GUI.set_font(self.font_a)
    local str_w, str_h = gfx.measurestr(self.caption)    
    
    gfx.x = self.x - str_w - self.pad
    gfx.y = self.y + (self.h - str_h) / 2
    
    GUI.txt_bg(self.caption, self.bg)
    GUI.txt_shadow(self.caption, self.col_cap, "shadow")

end


function GUI.Menubox:draw_text()

    -- Make sure retval hasn't been accidentally set to something illegal
    self.retval = self:validate_option(tonumber(self.retval) or 1)

    -- Strip gfx.showmenu's special characters from the displayed value
	local text = string.match(self.opt_array[self.retval], "^[<!#]?(.+)")

	-- Draw the text
	GUI.set_font(self.font_b)
	GUI.set_color(self.col_txt)
	
	--if self.output then text = self.output(text) end
    
    if self.output then
        local t = type(self.output)

        if t == "string" or t == "number" then
            text = self.output
        elseif t == "table" then
            text = self.output[text]
        elseif t == "function" then
            text = self.output(text)
        end
    end
    
    -- Avoid any crashes from weird user data
    text = tostring(text)


    str_w, str_h = gfx.measurestr(text)
	gfx.x = self.x + 4
	gfx.y = self.y + (self.h - str_h) / 2
    
    local r = gfx.x + self.w - 8 - (self.no_arrow and 0 or self.h)
    local b = gfx.y + str_h
	gfx.drawstr(text, self.align, r, b)       
    
end


------------------------------------
-------- Input helpers -------------
------------------------------------


-- Put together a string for gfx.showmenu from the values in opt_array
function GUI.Menubox:prep_menu()

	local str_arr = {}
    local sep_arr = {}    
    local menu_str = ""
    
	for i = 1, #self.opt_array do
		
		-- Check off the currently-selected option
		if i == self.retval then menu_str = menu_str .. "!" end

        table.insert(str_arr, tostring( type(self.opt_array[i]) == "table"
                                            and self.opt_array[i][1]
                                            or  self.opt_array[i]
                                      )
                    )

		if str_arr[#str_arr] == ""
		or string.sub(str_arr[#str_arr], 1, 1) == ">" then 
			table.insert(sep_arr, i) 
		end

		table.insert( str_arr, "|" )

	end
	
	menu_str = table.concat( str_arr )
	
	return string.sub(menu_str, 1, string.len(menu_str) - 1), sep_arr

end


-- Adjust the menu's returned value to ignore any separators ( --------- )
function GUI.Menubox:strip_seps(cur_opt, sep_arr)

    for i = 1, #sep_arr do
        if cur_opt >= sep_arr[i] then
            cur_opt = cur_opt + 1
        else
            break
        end
    end
    
    return cur_opt
    
end    


function GUI.Menubox:validate_option(val, dir)

    dir = dir or 1
    
    while true do

        -- Past the first option, look upward instead
        if val < 1 then
            val = 1
            dir = 1        

        -- Past the last option, look downward instead
        elseif val > #self.opt_array then
            val = #self.opt_array
            dir = -1

        end
        
        -- Don't stop on separators, folders, or grayed-out options        
        local opt = string.sub(self.opt_array[val], 1, 1)
        if opt == "" or opt == ">" or opt == "#" then
            val = val - dir
            
        -- This option is good
        else
            break
        end
    
    end

    return val    
    
end
