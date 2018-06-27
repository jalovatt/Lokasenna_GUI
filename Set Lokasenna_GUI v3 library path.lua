local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

reaper.SetExtState("Lokasenna_GUI", "lib_path_v3", script_path .. "Library/", true)