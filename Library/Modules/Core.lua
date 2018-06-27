------------------------------------
-------- Main functions ------------
------------------------------------


-- All elements are stored here. Don't put them anywhere else, or
-- Main will never find them.
GUI.elms = {}

-- On each draw loop, only layers that are set to true in this table
-- will be redrawn; if false, it will just copy them from the buffer
-- Set [0] = true to redraw everything.
GUI.redraw_layers = {}
GUI.redraw_z = function(z)
    
    GUI.redraw_layers[z] = true
    
end

-- Maintain a list of all GUI elements, sorted by their z order	
-- Also removes any elements with z = -1, for automatically
-- cleaning things up.
GUI.elms_list = {}
GUI.z_max = 0
GUI.update_elms_list = function (init)

	local z_table = {}
	GUI.z_max = 0

	for key, __ in pairs(GUI.elms) do

		local z = GUI.elms[key].z or 5

		-- Delete elements if the script asked to
		if z == -1 then
			
			GUI.elms[key]:on_delete()
			GUI.elms[key] = nil
			
		else

			if z_table[z] then
				table.insert(z_table[z], key)

			else
				z_table[z] = {key}

			end
		
		end
		
		if init then 
			
			GUI.elms[key]:init()

		end

		GUI.z_max = math.max(z, GUI.z_max)

	end

	GUI.elms_list = z_table
	
end

GUI.elms_hide = {}
GUI.elms_freeze = {}


GUI.wnd = {}

GUI.Init = function ()
    xpcall( function()
        
        
        -- Create the window
        gfx.clear = reaper.ColorToNative(table.unpack(GUI.colors.wnd_bg))
        
        if not GUI.wnd.x then GUI.wnd.x = 0 end
        if not GUI.wnd.y then GUI.wnd.y = 0 end
        if not GUI.wnd.w then GUI.wnd.w = 640 end
        if not GUI.wnd.h then GUI.wnd.h = 480 end

        if GUI.wnd.anchor and GUI.wnd.corner then
            GUI.wnd.x, GUI.wnd.y = GUI.get_window_pos(  GUI.wnd.x, GUI.wnd.y, GUI.wnd.w, GUI.wnd.h, 
                                                GUI.wnd.anchor, GUI.wnd.corner)
        end
            
        gfx.init(GUI.wnd.name, GUI.wnd.w, GUI.wnd.h, GUI.wnd.dock or 0, GUI.wnd.x, GUI.wnd.y)
        
        
        GUI.wnd.cur_w, GUI.wnd.cur_h = gfx.w, gfx.h

        -- Measure the window's title bar, in case we need it
        local __, __, wnd_y, __, __ = gfx.dock(-1, 0, 0, 0, 0)
        local __, gui_y = gfx.clienttoscreen(0, 0)
        GUI.title_height = gui_y - wnd_y


        -- Initialize a few values
        GUI.last_time = 0
        GUI.mouse = {
        
            x = 0,
            y = 0,
            cap = 0,
            down = false,
            wheel = 0,
            lwheel = 0
            
        }
      
        -- Store which element the mouse was clicked on.
        -- This is essential for allowing drag behaviour where dragging affects 
        -- the element position.
        GUI.mouse_down_elm = nil
        GUI.r_mouse_down_elm = nil
        GUI.m_mouse_down_elm = nil
            
        -- Convert color presets from 0..255 to 0..1
        for i, col in pairs(GUI.colors) do
            col[1], col[2], col[3], col[4] =    col[1] / 255, col[2] / 255, 
                                                col[3] / 255, col[4] / 255
        end
        
        -- Initialize the tables for our z-order functions
        GUI.update_elms_list(true)	
        
        if GUI.exit then reaper.atexit(GUI.exit) end
        
        GUI.gfx_open = true

    end, GUI.crash)
end

GUI.Main = function ()
    xpcall( function ()    

        if GUI.Main_Update_State() == 0 then return end

        GUI.Main_Update_Elms()

        -- If the user gave us a function to run, check to see if it needs to be 
        -- run again, and do so. 
        if GUI.func then
            
            local new_time = reaper.time_precise()
            if new_time - GUI.last_time >= (GUI.freq or 1) then
                GUI.func()
                GUI.last_time = new_time
            
            end
        end
        
        
        -- Maintain a list of elms and zs in case any have been moved or deleted
        GUI.update_elms_list()    
        
        
        GUI.Main_Draw()

    end, GUI.crash)
end


GUI.Main_Update_State = function()
    
	-- Update mouse and keyboard state, window dimensions
    if GUI.mouse.x ~= gfx.mouse_x or GUI.mouse.y ~= gfx.mouse_y then
        
        GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
        GUI.mouse.x, GUI.mouse.y = gfx.mouse_x, gfx.mouse_y
        
        -- Hook for user code
        if GUI.on_mouse_move then GUI.on_mouse_move() end
       
    else
    
        GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
       
    end
	GUI.mouse.wheel = gfx.mouse_wheel
	GUI.mouse.cap = gfx.mouse_cap
	GUI.char = gfx.getchar() 
	
	if GUI.wnd.cur_w ~= gfx.w or GUI.wnd.cur_h ~= gfx.h then
		GUI.wnd.cur_w, GUI.wnd.cur_h = gfx.w, gfx.h
        
		GUI.resized = true
        
        -- Hook for user code
        if GUI.on_resize then GUI.on_resize() end
        
	else
		GUI.resized = false
	end
	
	--	(Escape key)	(Window closed)		(User function says to close)
	--if GUI.char == 27 or GUI.char == -1 or GUI.quit == true then
	if (GUI.char == 27 and not (	GUI.mouse.cap & 4 == 4 
								or 	GUI.mouse.cap & 8 == 8 
								or 	GUI.mouse.cap & 16 == 16
                                or  GUI.escape_bypass))
			or GUI.char == -1 
			or GUI.quit == true then
		
        GUI.clear_tooltip()
		return 0
	else
        if GUI.char == 27 and GUI.escape_bypass then GUI.escape_bypass = "close" end
		reaper.defer(GUI.Main)
	end
    
end


--[[
	Update each element's state, starting from the top down.
	
	This is very important, so that lower elements don't
	"steal" the mouse.
	
	
	This function will also delete any elements that have their z set to -1

	Handy for something like Label:fade if you just want to remove
	the faded element entirely
	
	***Don't try to remove elements in the middle of the Update
	loop; use this instead to have them automatically cleaned up***	
	
]]--
GUI.Main_Update_Elms = function ()
    
    -- Disabled May 2/2018 to see if it was actually necessary
	-- GUI.update_elms_list()
	
	-- We'll use this to shorten each elm's update loop if the user did something
	-- Slightly more efficient, and averts any bugs from false positives
	GUI.elm_updated = false

	-- Check for the dev mode toggle before we get too excited about updating elms
	if  GUI.char == 282         and GUI.mouse.cap & 4 ~= 0 
    and GUI.mouse.cap & 8 ~= 0  and GUI.mouse.cap & 16 ~= 0 then
		
		GUI.dev_mode = not GUI.dev_mode
		GUI.elm_updated = true
		GUI.redraw_z(0)
		
	end	

    
    -- Mouse was moved? Clear the tooltip
    if GUI.tooltip and (GUI.mouse.x - GUI.mouse.lx > 0 or GUI.mouse.y - GUI.mouse.ly > 0) then
    
        GUI.mouseover_elm = nil
        GUI.clear_tooltip()

    end


    -- Bypass for some skip logic to allow tabbing between elements (GUI.tab_to_next)
    if GUI.new_focused_elm then
        GUI.new_focused_elm.focus = true
        GUI.new_focused_elm = nil
    end
    
    
	for i = 0, GUI.z_max do
		if  GUI.elms_list[i] and #GUI.elms_list[i] > 0 
        and not (GUI.elms_hide[i] or GUI.elms_freeze[i]) then
			for __, elm in pairs(GUI.elms_list[i]) do

				if elm and GUI.elms[elm] then GUI.Update(GUI.elms[elm]) end
				
			end
		end
		
	end

	-- Just in case any user functions want to know...
	GUI.mouse.last_down   = GUI.mouse.down
	GUI.mouse.r_last_down = GUI.mouse.r_down
    GUI.mouse.m_last_down = GUI.mouse.m_down

end

    
GUI.Main_Draw = function ()    
    
	-- Redraw all of the elements, starting from the bottom up.
	local w, h = GUI.wnd.cur_w, GUI.wnd.cur_h

	local need_redraw, global_redraw
	if GUI.redraw_layers[0] then
		global_redraw = true
        GUI.redraw_layers[0]= false
	else
		for z, b in pairs(GUI.redraw_layers) do
			if b == true then 
				need_redraw = true 
				break
			end
		end
	end

	if need_redraw or global_redraw then
		
		-- All of the layers will be drawn to their own buffer (dest = z), then
		-- composited in buffer 0. This allows buffer 0 to be blitted as a whole
		-- when none of the layers need to be redrawn.
		
		gfx.dest = 0
		gfx.setimgdim(0, -1, -1)
		gfx.setimgdim(0, w, h)

		GUI.set_color("wnd_bg")
		gfx.rect(0, 0, w, h, 1)

		for i = GUI.z_max, 0, -1 do
			if  GUI.elms_list[i] and #GUI.elms_list[i] > 0 
            and not GUI.elms_hide[i] then

				if global_redraw or GUI.redraw_layers[i] then
					
					-- Set this before we redraw, so that elms can call a redraw 
                    -- from their own :draw method. e.g. Labels fading out
                GUI.redraw_layers[i] = false

					gfx.setimgdim(i, -1, -1)
					gfx.setimgdim(i, w, h)
					gfx.dest = i
					
					for __, elm in pairs(GUI.elms_list[i]) do
						if not GUI.elms[elm] then 
                            reaper.MB(  "Error: Tried to update a GUI element that doesn't exist:"..
                                        "\nGUI.elms." .. tostring(elm), "Whoops!", 0)
                        end                                    
                        
                        -- Reset these just in case an element or some user code forgot to,
                        -- otherwise we get things like the whole buffer being blitted with a=0.2
                        gfx.mode = 0
                        gfx.set(0, 0, 0, 1)
                        
						GUI.elms[elm]:draw()
					end

					gfx.dest = 0
				end
							
				gfx.blit(i, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
			end
		end

        -- Draw developer hints if necessary
        if GUI.dev_mode then
            GUI.Draw_Dev()
        else		
            GUI.Draw_Version()		
        end
		
	end
   
		
    -- Reset them again, to be extra sure
	gfx.mode = 0
	gfx.set(0, 0, 0, 1)
	
	gfx.dest = -1
	gfx.blit(0, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
	
	gfx.update()

end



-- Display the GUI version number
-- Set GUI.version = 0 to hide this
GUI.Draw_Version = function ()
	
	if not GUI.version then return 0 end

	local str = "Lokasenna_GUI "..GUI.version
	
	GUI.set_font("version")
	GUI.set_color("txt")
	
	local str_w, str_h = gfx.measurestr(str)

	gfx.x = gfx.w - str_w - 6
	gfx.y = gfx.h - str_h - 4
	
	gfx.drawstr(str)	
	
end




------------------------------------
-------- Element functions ---------
------------------------------------


--[[
    Wrapper for creating new elements, allows them to know their own name
    If called after the script window has opened, will also run their :init
    method.
    Can be given a user class directly by passing the class itself as 'elm',
    or if 'elm' is a string will look for a class in GUI[elm]

    Elements can be created in two ways:

        ex. Label:  name, z, x, y, caption[, shadow, font, color, bg]
        
    1. Function arguments

                name        type
        GUI.new("my_label", "Label", 1, 16, 16, "Hello!", true, 1, "red", "white")
        
        
    2. Keyed tables
    
        GUI.new({
            name = "my_label",
            type = "Label",
            z = 1,
            x = 16,
            y = 16,
            caption = "Hello!",
            shadow = true,
            font = 1,
            color = "red",
            bg = "white"
        })   
        
    The only functional difference is that, when using a keyed table, additional parameters can
    be specified beyond the basic creation parameters given for that class. When using method 1,
    any additional parameters simply have to be specified afterward via:
    
        GUI.elms.my_label.shadow = false
        
    See the class documentation for more detail.
]]--
GUI.new = function (name, elm, ...)

    -- Support for passing all of the element params as a single keyed table
    local name = name
    local elm = elm
    local params
    if not elm and type(name) == "table" then
        
        -- Copy the table so we can pass it on
        params = name
        
        -- Grab the name and type
        elm = name.type
        name = name.name
        
    end
        
        
    -- Support for passing element classes directly as a table
    local elm = type(elm) == "string"   and GUI[elm]
                                        or  elm

    -- If we don't have an elm at this point there's a problem
    if not elm or type(elm) ~= "table" then
		reaper.ShowMessageBox(  "Unable to create element '"..tostring(name)..
                                "'.\nClass '"..tostring(elm).."' isn't available.", 
                                "GUI Error", 0)
		GUI.quit = true
		return nil
	end
    
    -- If we're overwriting a previous elm, make sure it frees its buffers, etc
    if GUI.elms[name] and GUI.elms.type then GUI.elms[name]:delete() end
    
    GUI.elms[name] = params and elm:new(name, params) or elm:new(name, ...)
	--GUI.elms[name] = elm:new(name, params or ...)
    
	if GUI.gfx_open then GUI.elms[name]:init() end
    
    -- Return this so (I think) a bunch of new elements could be created
    -- within a table that would end up holding their names for easy bulk
    -- processing.

    return name
	
end


--  Create multiple elms at once
--[[
    Pass a table of keyed tables for each element:

    local elms = {}
    elms.my_label = {
        type = "Label"
        x = 16
        ...
    }
    elms.my_button = {
        type = "Button"
        ...
    }
    
    GUI.create_elms(elms)
    

]]--
GUI.create_elms = function(elms)
    
    for name, params in pairs(elms) do
        params.name = name
        GUI.new(params)
    end    
    
end


GUI.take_focus = function(elm)
    
    elm.focus = true
    GUI.focused_elm = elm
    
end

--	See if the any of the given element's methods need to be called
GUI.Update = function (elm)
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	local x_delta, y_delta = x-GUI.mouse.lx, y-GUI.mouse.ly
	local wheel = GUI.mouse.wheel
	local inside = GUI.is_inside(elm, x, y)
	
	local skip = elm:on_update() or false
    
    if GUI.resized then elm:on_resize() end
    
	if GUI.elm_updated or (elm.focus and elm ~= GUI.focused_elm) then
		if elm.focus then
			elm.focus = false
			elm:lost_focus()
		end
		skip = true
	end


	if skip then return end
    
    
    local take_focus
    
    local buttons = {{btn = "", cap = 1}, {btn = "r_", cap = 2}, {btn = "m_", cap = 64}}
    for i = 1, #buttons do
        
        local btn = buttons[i].btn

        local last_down = btn .. "last_down"
        local mouse_down_elm = btn .. "mouse_down_elm"
        local downtime = btn .. "downtime"
        local double_clicked = btn .. "double_clicked"
        local down = btn .. "down"
        local ox, oy = btn .. "ox", btn .. "oy"
        local off_x, off_y = btn .. "off_x", btn .. "off_y"
        local lx, ly = btn .. "lx", btn .. "ly"

        if GUI.mouse.cap& buttons[i].cap == buttons[i].cap then
            
            -- If it wasn't down already...
            if not GUI.mouse[last_down] then

                -- Was a different element clicked?
                if not inside then 
                    if GUI[mouse_down_elm] == elm then
                        -- Should have been reset by the mouse-up, but in case...
                        GUI[mouse_down_elm] = nil
                    end
                    --elm.focus = false
                else
                
                    -- Prevent click-through
                    if GUI[mouse_down_elm] == nil then 

                        GUI[mouse_down_elm] = elm

                            -- Double clicked?
                        if GUI.mouse[downtime]
                        and reaper.time_precise() - GUI.mouse[downtime] < 0.20 
                        then

                            GUI.mouse[downtime] = nil
                            GUI.mouse[double_clicked] = true
                            --GUI.take_focus(elm)
                            elm["on_"..btn.."double_click"](elm)

                        elseif not GUI.mouse[double_clicked] then

                            GUI.take_focus(elm)
                            elm["on_"..btn.."mouse_down"](elm)

                        end

                        GUI.elm_updated = true

                    end
                    
                    GUI.mouse[down] = true
                    GUI.mouse[ox], GUI.mouse[oy] = x, y
                    
                    -- Where in the elm the mouse was clicked. For dragging stuff
                    -- and keeping it in the place relative to the cursor.
                    GUI.mouse[off_x], GUI.mouse[off_y] = x - elm.x, y - elm.y                    

                end
                
        
            -- 		Dragging? Did the mouse start out in this element?
            elseif (x_delta ~= 0 or y_delta ~= 0) 
            and     GUI[mouse_down_elm] == elm then
            
                if elm == GUI.focused_elm then 

                    elm["on_"..btn.."drag"](elm, x_delta, y_delta)
                    GUI.elm_updated = true

                end

            end


        -- If it was originally clicked in this element and has been released
        elseif GUI.mouse[down] and GUI[mouse_down_elm].name == elm.name then 
        
            GUI[mouse_down_elm] = nil
        
            if not GUI.mouse[double_clicked] then 
                
                --GUI.take_focus(elm)
                elm["on_"..btn.."mouse_up"](elm) 
                
            end

            GUI.elm_updated = true
            GUI.mouse[down] = false
            GUI.mouse[double_clicked] = false
            GUI.mouse[ox], GUI.mouse[oy] = -1, -1
            GUI.mouse[off_x], GUI.mouse[off_y] = -1, -1
            GUI.mouse[lx], GUI.mouse[ly] = -1, -1
            GUI.mouse[downtime] = reaper.time_precise()

        end    
        
    end	
	
    if take_focus then GUI.take_focus(elm) end
    
	-- If the mouse is hovering over the element
	if inside and not GUI.mouse.down and not GUI.mouse.r_down then
		elm:on_mouseover()
        
        -- Initial mouseover on an element
        if GUI.mouseover_elm ~= elm then
            GUI.mouseover_elm = elm
            GUI.mouseover_time = reaper.time_precise()
            
        -- Mouse was moved; reset the timer
        elseif x_delta > 0 or y_delta > 0 then
        
            GUI.mouseover_time = reaper.time_precise()
            
        -- Display a tooltip
        elseif (reaper.time_precise() - GUI.mouseover_time) >= GUI.tooltip_time then

            GUI.set_tooltip(elm.tooltip)
        
        end

	end
	
	
	-- If the mousewheel's state has changed
	if inside and GUI.mouse.wheel ~= GUI.mouse.lwheel then
		
		GUI.mouse.inc = (GUI.mouse.wheel - GUI.mouse.lwheel) / 120
		
		elm:on_wheel(GUI.mouse.inc)
		GUI.elm_updated = true
		GUI.mouse.lwheel = GUI.mouse.wheel
	
	end
	
	-- If the element is in focus and the user typed something
	if elm.focus and GUI.char ~= 0 then
		elm:on_type() 
		GUI.elm_updated = true
	end
	
end


--[[	Return or change an element's value
	
	For use with external user functions. Returns the given element's current 
	value or, if specified, sets a new one.	Changing values with this is often 
	preferable to setting them directly, as most :val methods will also update 
	some internal parameters and redraw the element when called.
]]--
GUI.val = function (elm, newval)

	if not GUI.elms[elm] then return nil end
	
	if newval then
		GUI.elms[elm]:val(newval)
	else
		return GUI.elms[elm]:val()
	end

end


