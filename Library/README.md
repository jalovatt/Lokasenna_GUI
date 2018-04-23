# Lokasenna_GUI
Lua GUI library for [REAPER][1] scripts
  
## Obligatory Preamble
As powerful as REAPER's scripting capabilities are, it offers nothing in the way of
providing a graphical interface for the end-user to make choices, tinker with settings, etc.
Many scripters opt to designate certain lines in the script with _USER_ _SETTINGS_
_HERE_ and _EDIT_ _THIS_ _LINE_, but - in my opinion - any feature that requires users to edit
.lua and .eel files directly is incomplete. Rude, even.
  
In the process of learning to write scripts for myself I found myself copying, pasting, and
extending the same fragments of code, cobbled together from a handful of forum threads
with examples of REAPER's graphical functions, and eventually decided to just stop what I
was doing and put it all together into a proper GUI toolkit.

Enjoy. :)

Or don't. See if I care.

## Usage
A basic script would look like this: 

1. Download all of these files, or use Git to mirror them, etc.
2. Load _Core.lua_ and any class libraries you want to use. Feel free to use
_requires()_, _loadfile()_, or whatever else you want.
```lua
    loadfile("/whatever_path_you_want/Core.lua")()
    loadfile("/whatever_path_you_want/Classes/Textbox.lua")()
    loadfile("/whatever_path_you_want/Classes/Button.lua")()
```
3. Provide a name, position, and dimensions for your script's window.
```lua
    GUI.name = "My script's window"
    GUI.x, GUI.y = 0, 0
    GUI.w, GUI.h = 256, 96
```
4. Create your GUI's elements.
```lua
            name         class      z  x    y   w,  h,  caption     
    GUI.New("my_txtbox", "Textbox", 1, 32,  32, 96, 20, "Track name:")
    
                                                                         min  max  steps  default
    GUI.New("my_slider", "Slider",  1, 192, 32, 48,     "Track number:", 1,   10,  10,    1)
    
                                                                    function
    GUI.New("my_button", "Button",  1, 64,  64, 48, 24, "Set name", set_track_name)
```
5. _set_track_name_ would, in this case, be a function declared previously in the script.
```lua
    local function set_track_name()
    
        local name = GUI.Val("my_txtbox")
        local num =  GUI.Val("my_slider")
    
        -- Do something with that information. Presumably renaming a track.
    
    end
```
6. Initialize the window.
```lua
    GUI.Init()
```
7. Start the main loop.
```lua
    GUI.Main()
```
That's it. You have a window, with a couple of things in it, so all you need to worry about
is making the things do what you want them to.  
## Further Detail
I'll try to keep the project Wiki up to date, but ultimately the best source of documentation
and examples is the _Example_ scripts and the library/class comments.



[1]: www.reaper.fm
