--[[	Lokasenna_GUI - Menubar clas
	
    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Menubar
    
    Creation parameters:
	name, z, x, y, menus[, w, h, pad]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


GUI.Menubar = GUI.Element:new()
function GUI.Menubar:new(name, z, x, y, menus, w, h, pad) -- Add your own params here
	
	local mnu = (not x and type(z) == "table") and z or {}
	
	mnu.name = name
	mnu.type = "Menubar"
	
	mnu.z = mnu.z or z

	mnu.x = mnu.x or x
    mnu.y = mnu.y or y
    
    mnu.font = mnu.font or 2
    mnu.col_txt = mnu.col_txt or "txt"
    mnu.col_bg = mnu.col_bg or "elm_frame"
    mnu.col_over = mnu.col_over or "elm_fill"
    
    if mnu.shadow == nil then
        mnu.shadow = true
    end

    mnu.w = mnu.w or w
    mnu.h = mnu.h or h
    
    if mnu.full_width == nil then
        mnu.full_width = true
    end

    -- Optional parameters should be given default values to avoid errors/crashes:
    mnu.pad = mnu.pad or pad or 0
    
    mnu.menus = mnu.menus or menus    
	
	GUI.redraw_z(mnu.z)
    
	setmetatable(mnu, self)
	self.__index = self
	return mnu

end


function GUI.Menubar:init()

    if gfx.w == 0 then return end
    
    self.buff = self.buff or GUI.get_buffer()

    -- We'll have to reset this manually since we're not running :init()
    -- until after the window is open
    local dest = gfx.dest
    
    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    
    
    -- Store some text measurements
    GUI.set_font(self.font)
    
    self.tab = gfx.measurestr(" ") * 4

    for i = 1, #self.menus do
       
        self.menus[i].width = gfx.measurestr(self.menus[i].title)
       
    end
    
    self.w = self.w or 0
    self.w = self.full_width and (GUI.wnd.cur_w - self.x) 
                             or  math.max(self.w, self:measure_titles(nil, true))
    self.h = self.h or gfx.texth
    
    
    -- Draw the background + shadow    
    gfx.setimgdim(self.buff, self.w, self.h * 2)
        
    GUI.set_color(self.col_bg)
    
    gfx.rect(0, 0, self.w, self.h, true)
    
    GUI.set_color("shadow")
    local r, g, b, a = table.unpack(GUI.colors["shadow"])
	gfx.set(r, g, b, 1)    
    gfx.rect(0, self.h + 1, self.w, self.h, true)
    gfx.muladdrect(0, self.h + 1, self.w, self.h, 1, 1, 1, a, 0, 0, 0, 0 )
    
    self.did_init = true
    
    gfx.dest = dest
    
end


function GUI.Menubar:draw()
	
    if not self.did_init then self:init() end
    
    local x, y = self.x, self.y
    local w, h = self.w, self.h

    -- Blit the menu background + shadow
    if self.shadow then
        
        for i = 1, GUI.shadow_dist do

            gfx.blit(self.buff, 1, 0, 0, h, w, h, x, y + i, w, h)
            
        end
        
    end
    
    gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y, w, h) 
    
    -- Draw menu titles
    self:draw_titles()
    
    -- Draw highlight
    if self.mouse_menu then self:draw_highlight() end
            
end


function GUI.Menubar:val(newval)
    
    if newval and type(newval) == "table" then
        
        self.menus = newval
        self.w, self.h = nil, nil
        self:init()
        self:redraw()
        
    else
    
        return self.menus

    end
    
end


function GUI.Menubar:on_resize()
    
    if self.full_width then 
        self:init() 
        self:redraw()
    end

end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function GUI.Menubar:draw_titles()
    
    local x = self.x

    GUI.set_font(self.font)
    GUI.set_color(self.col_txt)

    for i = 1, #self.menus do

        local str = self.menus[i].title
        local str_w, _ = gfx.measurestr(str)

        gfx.x = x + (self.tab + self.pad) / 2
        gfx.y = self.y
        
        gfx.drawstr(str)
        
        x = x + str_w + self.tab + self.pad
        
    end
    
end


function GUI.Menubar:draw_highlight()

    if self.menus[self.mouse_menu].title == "" then return end

    GUI.set_color(self.col_over)
    gfx.mode = 1
    --                                Hover  Click
    gfx.a = GUI.mouse.cap & 1 ~= 1 and 0.3 or 0.5
    
    gfx.rect(self.x + self.mouse_menu_x, self.y, self.menus[self.mouse_menu].width + self.tab + self.pad, self.h, true)
    
    gfx.a = 1
    gfx.mode = 0        
    
end




------------------------------------
-------- Input methods -------------
------------------------------------


-- Make sure to disable the highlight if the mouse leaves
function GUI.Menubar:on_update()
   
    if self.mouse_menu and not GUI.is_inside(self, GUI.mouse.x, GUI.mouse.y) then
        self.mouse_menu = nil
        self.mouse_menu_x = nil
        self:redraw()
        
        -- Skip the rest of the update loop for this elm
        return true
    end
    
end



function GUI.Menubar:on_mouse_up()

    if not self.mouse_menu then return end

    gfx.x, gfx.y = self.x + self:measure_titles(self.mouse_menu - 1, true), self.y + self.h
    local menu_str, sep_arr = self:prep_menu()
    local opt = gfx.showmenu(menu_str)

	if #sep_arr > 0 then opt = self:strip_seps(opt, sep_arr) end	

    if opt > 0 then
       
       self.menus[self.mouse_menu].options[opt][2]()
        
    end
    
	self:redraw()
    
end


function GUI.Menubar:on_mouse_down()
    
    self:redraw()
    
end


function GUI.Menubar:on_mouseover()
        
    local opt = self.mouse_menu
    
    local x = GUI.mouse.x - self.x

    if  self.mouse_menu_x and x > self:measure_titles(nil, true) then
        
        self.mouse_menu = nil
        self.mouse_menu_x = nil
        self:redraw()
        
        return
        
    end
        

    -- Iterate through the titles by overall width until we
    -- find which one the mouse is in.
    for i = 1, #self.menus do

        if x <= self:measure_titles(i, true) then
            
            self.mouse_menu = i
            self.mouse_menu_x = self:measure_titles(i - 1, true)

            if self.mouse_menu ~= opt then self:redraw() end

            return
        end
       
    end
    
end


function GUI.Menubar:on_drag()
    
    self:on_mouseover()
    
end


------------------------------------
-------- Menu methods --------------
------------------------------------


-- Return a table of the menu titles
function GUI.Menubar:gettitles()
   
   local tmp = {}
   for i = 1, #self.menus do
       tmp[i] = self.menus.title
   end
   
   return tmp
    
end


-- Returns the length of the specified number of menu titles, or 
-- all of them if 'num' isn't given
-- Will include tabs + padding if tabs = true
function GUI.Menubar:measure_titles(num, tabs)
    
    local len = 0
    
    for i = 1, num or #self.menus do
        
        len = len + self.menus[i].width
        
    end
    
    return not tabs and len 
                    or (len + (self.tab + self.pad) * (num or #self.menus))

end


-- Parse the current menu into a string for gfx.showmenu
-- Returns the string and a table of separators for offsetting the
-- value returned when the user clicks something.
function GUI.Menubar:prep_menu()

    local arr = self.menus[self.mouse_menu].options

    local sep_arr = {}
	local str_arr = {}
    local menu_str = ""
    
	for i = 1, #arr do
		      
        table.insert(str_arr, arr[i][1])

		if str_arr[#str_arr] == ""
		or string.sub(str_arr[#str_arr], 1, 1) == ">" then 
			table.insert(sep_arr, i) 
		end

		table.insert( str_arr, "|" )

	end
	
	menu_str = table.concat( str_arr )
	
	return string.sub(menu_str, 1, string.len(menu_str) - 1), sep_arr

end


-- Adjust the returned value to account for any separators,
-- since gfx.showmenu doesn't count them
function GUI.Menubar:strip_seps(opt, sep_arr)

    for i = 1, #sep_arr do
        if opt >= sep_arr[i] then
            opt = opt + 1
        else
            break
        end
    end
    
    return opt
    
end 