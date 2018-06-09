--[[
    Lokasenna_GUI example
    
    - General demonstration
	- Tabs and layer sets
    - Subwindows
	- Accessing elements' parameters

]]--
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]


-- I hate working with 'requires', so I've opted to do it this way.
-- This also works much more easily with my Script Compiler.
local function req(file)
	
	if missing_lib then return function () end end
	
    local ret, err = loadfile(( file:sub(2, 2) == ":" and "" or script_path) .. file)
	if not ret then
		reaper.ShowMessageBox("Couldn't load "..file.."\n\nError: "..tostring(err), "Library error", 0)
		missing_lib = true		
		return function () end

	else 
		return ret
	end	

end


-- The Core library must be loaded prior to any classes, or the classes will throw up errors
-- when they look for functions that aren't there.
req("Core.lua")()
req("Classes/Class - Button.lua")()
req("Classes/Class - Textbox.lua")()
req("Classes/Class - Window.lua")()
req("Modules/Module - GetUserInputs.lua")()


-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end





GUI.name = "GetUserInputs test"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 240
GUI.anchor, GUI.corner = "mouse", "C"


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

GUI.CreateElms(elms)

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