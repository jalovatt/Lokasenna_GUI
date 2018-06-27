

-- Print a string to the Reaper console.
GUI.Msg = function (str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end



-- Developer mode settings
GUI.dev = {
	
	-- grid_a must be a multiple of grid_b, or it will
	-- probably never be drawn
	grid_a = 128,
	grid_b = 16
	
}


-- Draws a grid overlay and some developer hints
-- Toggled via Ctrl+Shift+Alt+Z, or by setting GUI.dev_mode = true
GUI.Draw_Dev = function ()
	    
	-- Draw a grid for placing elements
	GUI.set_color("magenta")
	gfx.setfont("Courier New", 10)
	
	for i = 0, GUI.wnd.w, GUI.dev.grid_b do
		
		local a = (i == 0) or (i % GUI.dev.grid_a == 0)
		gfx.a = a and 1 or 0.3
		gfx.line(i, 0, i, GUI.wnd.h)
		gfx.line(0, i, GUI.wnd.w, i)
		if a then
			gfx.x, gfx.y = i + 4, 4
			gfx.drawstr(i)
			gfx.x, gfx.y = 4, i + 4
			gfx.drawstr(i)
		end	
	
	end
    
    local str = "Mouse: "..math.modf(GUI.mouse.x)..", "..math.modf(GUI.mouse.y).." "
    local str_w, str_h = gfx.measurestr(str)
    gfx.x, gfx.y = GUI.wnd.w - str_w - 2, GUI.wnd.h - 2*str_h - 2
    
    GUI.set_color("black")
    gfx.rect(gfx.x - 2, gfx.y - 2, str_w + 4, 2*str_h + 4, true)
    
    GUI.set_color("white")
    gfx.drawstr(str)
   
    local snap_x, snap_y = GUI.nearest_multiple(GUI.mouse.x, GUI.dev.grid_b),
                           GUI.nearest_multiple(GUI.mouse.y, GUI.dev.grid_b)
    
    gfx.x, gfx.y = GUI.wnd.w - str_w - 2, GUI.wnd.h - str_h - 2
	gfx.drawstr(" Snap: "..snap_x..", "..snap_y)
    
	gfx.a = 1
    
    GUI.redraw_z(0)
	
end



