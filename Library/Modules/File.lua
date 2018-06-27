------------------------------------
-------- File/Storage functions ----
------------------------------------


--[[	Use when working with file paths if you need to add your own /s
    (Borrowed from X-Raym)
        
        Apr. 22/18 - Further reading leads me to believe that simply using
        '/' as a separator should work just fine on Windows, Mac, and Linux.
]]--
GUI.file_sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"


-- To open files in their default app, or URLs in a browser
-- Copied from Heda; cheers!
GUI.open_file = function (path)

	local OS = reaper.GetOS()
    
    if OS == "OSX32" or OS == "OSX64" then
		os.execute('open "" "' .. path .. '"')
	else
		os.execute('start "" "' .. path .. '"')
	end
  
end


-- Saves the current script window parameters to an ExtState under the given section name
-- Returns dock, x, y, w, h
GUI.save_window_state = function (name)
    
    if not name then return end    
    local state = {gfx.dock(-1, 0, 0, 0, 0)}
    reaper.SetExtState(name, "window", table.concat(state, ","), true)
    
    return table.unpack(state)
    
end


-- Looks for an ExtState containing saved window parameters and reapplies them
-- Call with noapply = true to just return the values
-- Returns dock, x, y, w, h
GUI.load_window_state = function (name, noapply)

    if not name then return end
    
    local str = reaper.GetExtState(name, "window")
    if not str or str == "" then return end

    local dock, x, y, w, h = string.match(str, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
    if not (dock and x and y and w and h) then return end
    GUI.wnd.dock, GUI.wnd.x, GUI.wnd.y, GUI.wnd.w, GUI.wnd.h = dock, x, y, w, h

    -- Probably don't want these messing up where the user put the window
    GUI.wnd.anchor, GUI.wnd.corner = nil, nil

    return dock, x, y, w, h
    
end



