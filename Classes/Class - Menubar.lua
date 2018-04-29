--[[	Lokasenna_GUI - Menubar clas
	
	---- User parameters ----

	(name, z, x, y, menus[, w, h, pad])

Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
w, h			Width and height of the Menubar
menus           Accepts a specifically formatted table.

                menus = {
                    
                    
                    -- Menu title
                    {title = "File", options = {
                    
                        -- Menu item            Function to run when clicked
                        {"New",                 mnu_file.new},
                        {""},
                        {"Open",                mnu_file.open},
                        {">Recent Files"},
                            {"blah.txt",        mnu_file.recent_blah},
                            {"stuff.txt",       mnu_file.recent_stuff},
                            {"<readme.md",      mnu_file.recent_readme},
                        {"Save",                mnu_file.save},
                        {"Save As",             mnu_file.save_as},
                        {""},
                        {"#Print",               mnu_file.print},
                        {"#Print Preview",       mnu_file.print_preview},
                        {""},
                        {"Exit",                mnu_file.exit}
                        
                    }},
                    
                    {title = "Edit", options = {....}},
                    
                    ...etc...
                    
                }

                - Menu options can be prefixed with the following:
                
                    ! : Checked
					# : grayed out
					> : this menu item shows a submenu
					< : last item in the current submenu
                    
                - An empty item ({""}) will appear as a separator in the menu.
                
                - Functions don't need to be in any particular format or even associated
                  with each other; this would also work:
                  
                        {"New",                 new_func),
                        {"Open",                open),
                        {"Save",                savestuff),
                
                

 
 

Optional:
w, h            Specify an overall width and height. If omitted, these will be calculated
                automatically from the menu titles
pad             Extra width added between menus. Defaults to 0.

Additional:
font            Font for the menu titles
col_txt         Color the menu titles
col_bg          Color for the menu bar
col_over        Color for the highlighted menu


Extra methods:


GUI.Val()		Returns the menu table
GUI.Val(new)	Accepts a new menu table and reinitializes some internal values.

                Should only be necessary if the menu titles need to be changed; for things 
                like checking off/graying out menu items, or even updating dynamic menus 
                like "Recent Files", it would probably be easier to just edit the
                ' options = {....} ' yourself and directly replace it:
                
                local new_file_options = GUI.elms.my_menubar.menus[1].options
                ...edit the names or whatever...
                GUI.elms.my_menubar.menus[1].options = new_file_options


]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


GUI.Menubar = GUI.Element:new()
function GUI.Menubar:new(name, z, x, y, menus, w, h, pad) -- Add your own params here
	
	local mnu = {}
	
	mnu.name = name
	mnu.type = "Menubar"
	
	mnu.z = z
	GUI.redraw_z[z] = true	
	
	mnu.x, mnu.y = x, y
    
    mnu.font = 2
    mnu.col_txt = "txt"
    mnu.col_bg = "elm_frame"
    mnu.col_over = "elm_fill"
    
    mnu.shadow = true

    mnu.w, h = w or nil, h or nil

    -- Optional parameters should be given default values to avoid errors/crashes:
    mnu.pad = pad or 0
    
    mnu.menus = menus    
	
	setmetatable(mnu, self)
	self.__index = self
	return mnu

end


function GUI.Menubar:init()

    if gfx.w == 0 then return end
    
    self.buff = self.buff or GUI.GetBuffer()

    -- We'll have to reset this manually since we're not running :init()
    -- until after the window is open
    local dest = gfx.dest
    
    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    
    
    -- Store some text measurements
    GUI.font(self.font)
    
    self.tab = gfx.measurestr(" ") * 4

    for i = 1, #self.menus do
       
        self.menus[i].width = gfx.measurestr(self.menus[i].title)
       
    end
    
    self.w = self.w or self:measuretitles(nil, true)
    self.h = self.h or gfx.texth
    
    
    -- Draw the background + shadow    
    gfx.setimgdim(self.buff, self.w * 2, self.h)
        
    GUI.color(self.col_bg)
    
    gfx.rect(0, 0, self.w, self.h, true)
    
    GUI.color("shadow")
    local r, g, b, a = table.unpack(GUI.colors["shadow"])
	gfx.set(r, g, b, 1)    
    gfx.rect(self.w + 1, 0, self.w, self.h, true)
    gfx.muladdrect(self.w + 1, 0, self.w, self.h, 1, 1, 1, a, 0, 0, 0, 0 )
    
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

            gfx.blit(self.buff, 1, 0, w + 1, 0, w, h, x, y + i, w, h)
            
        end
        
    end
    
    gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y, w, h) 
    
    -- Draw menu titles
    self:drawtitles()
    
    -- Draw highlight
    if self.mousemnu then self:drawhighlight() end
            
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

------------------------------------
-------- Drawing methods -----------
------------------------------------


function GUI.Menubar:drawtitles()
    
    local x = self.x

    GUI.font(self.font)
    GUI.color(self.col_txt)

    for i = 1, #self.menus do

        local str = self.menus[i].title
        local str_w, _ = gfx.measurestr(str)

        gfx.x = x + (self.tab + self.pad) / 2
        gfx.y = self.y
        
        gfx.drawstr(str)
        
        x = x + str_w + self.tab + self.pad
        
    end
    
end


function GUI.Menubar:drawhighlight()

    GUI.color(self.col_over)
    gfx.mode = 1
    --                                Hover  Click
    gfx.a = GUI.mouse.cap & 1 ~= 1 and 0.3 or 0.5
    
    
    gfx.rect(self.mousemnu_x, self.y, self.menus[self.mousemnu].width + self.tab + self.pad, self.h, true)
    
    gfx.a = 1
    gfx.mode = 0        
    
end




------------------------------------
-------- Input methods -------------
------------------------------------


-- Make sure to disable the highlight if the mouse leaves
function GUI.Menubar:onupdate()
   
    if self.mousemnu and not GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
        self.mousemnu = nil
        self.mousemnu_x = nil
        self:redraw()
        
        -- Skip the rest of the update loop for this elm
        return true
    end
    
end



function GUI.Menubar:onmouseup()

    if not self.mousemnu then return end

    gfx.x, gfx.y = self.x + self:measuretitles(self.mousemnu - 1, true), self.y + self.h
    local menu_str, sep_arr = self:prepmenu()
    local opt = gfx.showmenu(menu_str)

	if #sep_arr > 0 then opt = self:stripseps(opt, sep_arr) end	

    if opt > 0 then
       
       self.menus[self.mousemnu].options[opt][2]()
        
    end
    
	self:redraw()
    
end


function GUI.Menubar:onmousedown()
    
    self:redraw()
    
end


function GUI.Menubar:onmouseover()
        
    local opt = self.mousemnu
    
    local x = GUI.mouse.x - self.x

    -- Iterate through the titles by overall width until we
    -- find which one the mouse is in.
    for i = 1, #self.menus do

        if x <= self:measuretitles(i, true) then
            
            self.mousemnu = i
            self.mousemnu_x = self:measuretitles(i - 1, true)

            if self.mousemnu ~= opt then self:redraw() end

            return
        end
       
    end
    
end


function GUI.Menubar:ondrag()
    
    self:onmouseover()
    
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
function GUI.Menubar:measuretitles(num, tabs)
    
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
function GUI.Menubar:prepmenu()

    local arr = self.menus[self.mousemnu].options

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
function GUI.Menubar:stripseps(opt, sep_arr)

    for i = 1, #sep_arr do
        if opt >= sep_arr[i] then
            opt = opt + 1
        else
            break
        end
    end
    
    return opt
    
end 