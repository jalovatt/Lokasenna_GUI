--[[
	
	Lokasenna_GUI 3.0
	
	Core functionality
	
]]--
GUI = {}

GUI.version = "3.0.0 beta"

GUI.lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v3")

GUI.script_path, GUI.script_name = ({reaper.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")


-- I hate working with 'requires', so I've opted to do it this way.
-- This also works much more easily with my Script Compiler.
GUI.req = function (file)
	
	if missing_lib then return function () end end
	
    file = (file:sub(2, 2) == ":" and "" or GUI.lib_path) .. file
    local ret, err = loadfile(file)
	if not ret then
		reaper.ShowMessageBox("Couldn't load "..file.."\n\nError: "..tostring(err), "Library error", 0)
		missing_lib = true
        GUI.error_message = "Missing library:\n" .. tostring(file)
		return function () end

	else 
		return ret
	end	

end

GUI.req("Modules/Error.lua")()
GUI.req("Modules/Core.lua")()
GUI.req("Modules/Element.lua")()
GUI.req("Modules/Buffer.lua")()
GUI.req("Modules/Color.lua")()
GUI.req("Modules/Developer.lua")()
GUI.req("Modules/File.lua")()
GUI.req("Modules/Graphics.lua")()
GUI.req("Modules/Math.lua")()
GUI.req("Modules/Reaper.lua")()
GUI.req("Modules/Settings.lua")()
GUI.req("Modules/Table.lua")()
GUI.req("Modules/Text.lua")()

-- Also might need to know this
GUI.SWS_exists = reaper.APIExists("CF_GetClipboardBig")
