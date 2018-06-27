--[[	Lokasenna_GUI - UserInputs window
	
    This module emulates the native reaper.GetUserInputss() dialog.
    
    The Window, Textbox, and Button classes are required.


]]--

if not (GUI and GUI.Window and GUI.Textbox and GUI.Button) then
	reaper.ShowMessageBox(  "Couldn't access some functions.\n\nUserInputs requires the Lokasenna_GUI "..
                            "Core script and the Window, Textbox, and Button classes.", 
                            "Library Error", 0)
	missing_lib = true
	return 0
end


local ref_txt = {x = 128, y = 16, w = 128 + (extra_width or 0), h = 20, off = 24}


local function check_window_size(w, h)
    
		-- If the window's size has been changed, reopen it
		-- at the current position with the size we specified
		local dock,wnd_x,wnd_y,wnd_w,wnd_h = gfx.dock(-1,0,0,0,0)
        
        if wnd_w < w or wnd_h < h then
            return {dock, wnd_x, wnd_y, wnd_w, wnd_h}
        end
        
end


local function resize_window(dock, x, y, w, h)

    gfx.quit()
    gfx.init(GUI.wnd.name, w, h, dock, x, y)
    GUI.redraw_z(0)
    GUI.wnd.cur_w, GUI.wnd.cur_h = w, h
    
end


local function return_values(apply, func)
    
    if apply then
        
        local vals = {}
        for i = 1, GUI.elms.UserInputs_wnd.num_inputs do
            vals[i] = GUI.val("UserInputs_txt_" .. i)
        end
        func(vals)
        
    else
    
        func(nil)
        
    end    
    
end


local function clear_UserInputs()
    
    -- Return the buffers we borrowed for our z_set
    GUI.free_buffer(GUI.elms.UserInputs_wnd.z_set)
    
    -- Delete any elms with "UserInput" in their name
    for k in pairs(GUI.elms) do
        if string.match(k, "UserInput") then
            GUI.elms[k]:delete()
        end
    end
    
end


local function wnd_open(self)
    
    self:adjust_child_elms()
    
    -- Place the OK/Cancel buttons appropriately
    GUI.elms.UserInputs_ok.x = self.x + (self.w / 2) - 72
    GUI.elms.UserInputs_cancel.x = self.x + (self.w / 2) + 8
    
end
    
local function wnd_close(self, apply)
    
    self:show_layers()
    
    return_values(apply, self.ret_func)
    
    GUI.escape_bypass = false

    if self.resize then
        
        -- Reopen window with initial size
        resize_window( table.unpack(self.resize) )       
        
    end



    clear_UserInputs()
    
end


local function txt_enter(self)
        
    self.focus = false
    self:lost_focus()
    self:redraw()
    
    GUI.elms.UserInputs_ok:exec()

end





-- retval, retvals_csv reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )

-- Opens a Window element with text fields for getting user input
-- captions and defaults will accept either a CSV or an indexed table
function GUI.GetUserInputs(title, captions, defaults, ret_func, extra_width)
    
    if not captions or type(captions) ~= "table" or #captions == 0 
    or not defaults or type(defaults) ~= "table" or #defaults == 0 then
        return
    end
    
    local caps, defs = captions, defaults
    
    --[[
    -- Support for passing either a CSV or a table
    local caps = {}
    if type(captions) == "string" then
        for str in string.gmatch(captions, "[^,]+") do
            caps[#caps+1] = str
        end
    elseif type(captions) == "table" then
        caps = captions
    end    
    
    local defs = {}
    if type(defaults) == "string" then
        for str in string.gmatch(defaults, "[^,]+") do
            defs[#defs+1] = str
        end
    elseif type(defaults) == "table" then
        defs = defaults
    end
    ]]--
    
    
    -- Figure out the window dimensions
    local w = ref_txt.x + ref_txt.w + 16
    local h = 16 + #caps * (ref_txt.off) + 80
    
    local z_set = GUI.get_buffer(2)
    table.sort(z_set)

    -- Set up the window
    --	name, z, x, y, w, h, caption, z_set[, center]
    local elms = {}
    elms.UserInputs_wnd = {
        type = "Window",
        z = z_set[2],
        x = 0,
        y = 0,
        w = w,
        h = h,
        caption = title or "",
        z_set = z_set,
        num_inputs = #caps,
        ret_func = ret_func,
    }
    
    -- Set up the textboxes
    for i = 1, #caps do
        
        elms["UserInputs_txt_" .. i] = {
            type = "Textbox",
            z = z_set[1],
            x = ref_txt.x,
            y = ref_txt.y + (i - 1)*ref_txt.off,
            w = ref_txt.w + (extra_width or 0),
            h = ref_txt.h,
            caption = caps[i] or "",
            retval = defs[i] or "",
            tab_idx = i,
        }

    end
    
    -- Set up the OK/Cancel buttons
    elms.UserInputs_ok = {
        type = "Button",
        z = z_set[1],
        x = 0,
        y = h - 64,
        w = 64,
        h = 24,
        caption = "OK",
    }
    elms.UserInputs_cancel = {
        type = "Button",
        z = z_set[1],
        x = 0,
        y = h - 64,
        w = 64,
        h = 24,
        caption = "Cancel"
        
    }
    
    -- Create the window and elements
    GUI.create_elms(elms)
    
    -- Our elms need to be in the master list for the Window's adjustment function to see them
    GUI.update_elms_list()

    -- Method overrides so we can return values and whatnot
    GUI.elms.UserInputs_wnd.on_open = wnd_open
    
    GUI.elms.UserInputs_wnd.close = wnd_close
    
    -- Return should also press the OK button
    for name in pairs( GUI.elms.UserInputs_wnd:get_child_elms() ) do
        if string.match(name, "txt") then
            GUI.elms[name].keys[GUI.chars.RETURN] = txt_enter
        end
    end
    
    GUI.elms.UserInputs_ok.func = function() GUI.elms.UserInputs_wnd:close(true) end
    GUI.elms.UserInputs_cancel.func = function() GUI.elms.UserInputs_wnd:close() end



    local resize = check_window_size(w, h)
    
    if resize then
        
        -- Reopen the window
        resize_window(resize[1], resize[2], resize[3], w, h)
    
        -- Store the resize values
        GUI.elms.UserInputs_wnd.resize = resize
        
    end



    GUI.elms.UserInputs_wnd:open()
    
end