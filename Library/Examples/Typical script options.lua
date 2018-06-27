--[[
	Lokasenna_GUI example
	
	- Getting user input before running an action; i.e. replacing GetUserInputs

]]--

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v3")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v3 library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Lokasenna_GUI.lua")()

GUI.req("Classes/Slider.lua")()
GUI.req("Classes/Button.lua")()
GUI.req("Classes/Menubox.lua")()
GUI.req("Classes/Options.lua")()




------------------------------------
-------- Functions  ----------------
------------------------------------


local function btn_click()
	
	-- Grab all of the user's settings into local variables,
	-- just to make it less awkward to work with
	local mode, thresh = GUI.val("mnu_mode"), GUI.val("sldr_thresh")
	local opts = GUI.val("chk_opts")
	local time_sel, sel_track, glue = opts[1], opts[2], opts[3]
	
	-- Be nice, give the user an Undo point
	reaper.Undo_BeginBlock()
	
	reaper.ShowMessageBox(
		"This is where we pretend to perform some sort of fancy operation with the user's settings.\n\n"
		.."Working in "..tostring(GUI.elms.mnu_mode.opt_array[mode])
		.." mode with a threshold of "..tostring(thresh).."db.\n\n"
		.."Apply only to time selection: "..tostring(time_sel).."\n"
		.."Apply only to selected track: "..tostring(sel_track).."\n"
		.."Glue the processed items together afterward: "..tostring(glue)
	, "Yay!", 0)
	
	
	reaper.Undo_EndBlock("Typical script options", 0)	
	
	-- Exit the script on the next update
	GUI.quit = true
	
end




------------------------------------
-------- Window settings -----------
------------------------------------


GUI.wnd.name = "Example - Typical script options"
GUI.wnd.x, GUI.wnd.y, GUI.wnd.w, GUI.wnd.h = 0, 0, 400, 200
GUI.wnd.anchor, GUI.wnd.corner = "mouse", "C"




------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[	

	Button		z, 	x, 	y, 	w, 	h, caption, func[, ...]
	Checklist	z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Menubox		z, 	x, 	y, 	w, 	h, caption, opts, pad, no_arrow]
	Slider		z, 	x, 	y, 	w, 	caption, min, max, defaults[, inc, dir]
	
]]--

GUI.new("mnu_mode",	"Menubox",		1, 64,	32,  72, 20, "Mode:", "Auto,Punch,Step")
GUI.new("chk_opts",	"Checklist",	1, 192,	32,  192, 96, "Options", "Only in time selection,Only on selected track,Glue items when finished", "v", 4)
GUI.new("sldr_thresh", "Slider",	1, 32,  96, 128, "Threshold", -60, 0, 48, nil, "h")
GUI.new("btn_go",	"Button",		1, 168, 152, 64, 24, "Go!", btn_click)


GUI.Init()
GUI.Main()