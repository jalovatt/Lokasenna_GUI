--[[
    
    Demonstration of the GetUserInputs window
    
]]--

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v3")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v3 library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Lokasenna_GUI.lua")()

GUI.req("Classes/Button.lua")()
GUI.req("Classes/Textbox.lua")()
GUI.req("Classes/Window.lua")()
GUI.req("Windows/GetUserInputs.lua")()




GUI.wnd.name = "GetUserInputs test"
GUI.wnd.x, GUI.wnd.y, GUI.wnd.w, GUI.wnd.h = 0, 0, 320, 240
GUI.wnd.anchor, GUI.wnd.corner = "mouse", "C"


--[[	

	Button		z, 	x, 	y, 	w, 	h, caption, func[, ...]
	Checklist	z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Frame		z, 	x, 	y, 	w, 	h[, shadow, fill, color, round]
	Knob		z, 	x, 	y, 	w, 	caption, min, max, default[, inc, vals]	
	Label		z, 	x, 	y,		caption[, shadow, font, color, bg]
	Menubox		z, 	x, 	y, 	w, 	h, caption, opts
	Radio		z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Slider		z, 	x, 	y, 	w, 	caption, min, max, defaults[, inc, dir]
	Tabs		z, 	x, 	y, 		tab_w, tab_h, opts[, pad]
	Textbox		z, 	x, 	y, 	w, 	h[, caption, pad]
    Window      z,  x,  y,  w,  h,  caption, z_set[, center]
	
]]--


-- Elements can be created in any order you want. I find it easiest to organize them
-- by tab, or by what part of the script they're involved in.

local elms = {}
elms.my_button = {
    type = "Button",
    z = 1,
    x = 48,
    y = 48,
    w = 64,
    h = 22,
    caption = "Inputs..."
}

GUI.create_elms(elms)

local function return_values(vals)
    
    if not vals then vals = {"cancelled"} end
    reaper.MB("Returned values:\n\n" .. table.concat(vals, "\n"), "Returned:", 0)
    
end

GUI.elms.my_button.func = function()
    
    --function GUI.GetUserInputs(title, captions, defaults, extra_width, ret_func)
    GUI.GetUserInputs("Type stuff, please", {"Option 1", "Option 2", "Option 3", "Option 4"}, {"Def 1", "Def 2", "Def 3", "Def 4"}, return_values, 0)
    
end

GUI.Init()

GUI.Main()