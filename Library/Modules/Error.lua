------------------------------------
-------- Error handling ------------
------------------------------------


-- Checks for Reaper's "restricted permissions" script mode
-- GUI.script_restricted will be true if restrictions are in place
-- Call GUI.error_restricted to display an error message about restricted permissions
-- and exit the script.
if not os then
    
    GUI.script_restricted = true
    
    GUI.error_restricted = function()

        reaper.MB(  "This script tried to access a function that isn't available in Reaper's 'restricted permissions' mode." ..
                    "\n\nThe script was NOT necessarily doing something malicious - restricted scripts are unable " ..
                    "to access a number of basic functions such as reading and writing files." ..
                    "\n\nPlease let the script's author know, or consider running the script without restrictions if you feel comfortable.",
                    "Script Error", 0)
        
        gfx.quit()
        GUI.quit = true
        GUI.error_message = "(Restricted permissions error)"
        
        return nil, "Error: Restricted permissions"
        
    end
    
    os = setmetatable({}, { __index = GUI.error_restricted })
    io = setmetatable({}, { __index = GUI.error_restricted })    
    
end


-- A basic crash handler, just to add some helpful detail
-- to the Reaper error message.
GUI.crash = function (errObject)
                             
    local by_line = "([^\r\n]*)\r?\n?"
    local trim_path = "[\\/]([^\\/]-:%d+:.+)$"
    local err = string.match(errObject, trim_path) or "Couldn't get error message."

    local trace = debug.traceback()
    local tmp = {}
    for line in string.gmatch(trace, by_line) do
        
        local str = string.match(line, trim_path) or line
        
        tmp[#tmp + 1] = str

    end
    
    local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)$")
    
    local ret = reaper.ShowMessageBox(name.." has crashed!\n\n"..
                                      "Would you like to have a crash report printed "..
                                      "to the Reaper console?", 
                                      "Oops", 4)
    
    if ret == 6 then 

        reaper.ShowConsoleMsg(  "Error: "..err.."\n"..
                                (GUI.error_message and tostring(GUI.error_message).."\n\n" or "\n") ..
                                "Stack traceback:\n\t"..table.concat(tmp, "\n\t", 2).."\n\n"..
                                "Lokasenna_GUI:\t".. GUI.version.."\n"..
                                "Reaper:       \t"..reaper.GetAppVersion().."\n"..
                                "Platform:     \t"..reaper.GetOS())
                                
    end
    
    gfx.quit()
    GUI.quit = true
    
end

