--[[
	Lokasenna_GUI

	- Blank GUI template

]]--

loadfile( reaper.GetExtState("Lokasenna_GUI", "lib_path_v3") .. "Lokasenna_GUI.lua" )
if not GUI then
    reaper.MB("Couldn't find the Lokasenna_GUI. Please run 'Set Lokasenna_GUI library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
    return
end

--[[
    Require element classes here
]]--


-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end




------------------------------------
-------- Window settings -----------
------------------------------------


GUI.wnd.name = "Example - Script template"
GUI.wnd.x, GUI.wnd.y, GUI.wnd.w, GUI.wnd.h = 0, 0, 400, 200
GUI.wnd.anchor, GUI.wnd.corner = "mouse", "C"


------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[
    Create new elements here
]]--


GUI.Init()
GUI.Main()