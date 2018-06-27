--[[	Lokasenna_GUI - Textbox class
	
    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Textbox
    
    Creation parameters:
	name, z, x, y, w, h[, caption, pad]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


-- Managing text is MUCH easier with a monospace font.
GUI.fonts.textbox = {"Courier", 16}


GUI.Textbox = GUI.Element:new()
function GUI.Textbox:new(name, z, x, y, w, h, caption, pad)
	
	local txt = (not x and type(z) == "table") and z or {}
	
	txt.name = name
	txt.type = "Textbox"
	
	txt.z = txt.z or z
	
	txt.x = txt.x or x
    txt.y = txt.y or y
    txt.w = txt.w or w
    txt.h = txt.h or h

    txt.retval = txt.retval or ""

	txt.caption = txt.caption or caption or ""
	txt.pad = txt.pad or pad or 4
	
    if txt.shadow == nil then
        txt.shadow = true
    end
	txt.bg = txt.bg or "wnd_bg"
	txt.color = txt.color or "txt"
	
	txt.font_a = txt.font_a or 3
    
	txt.font_b = txt.font_b or "textbox"
    
    txt.cap_pos = txt.cap_pos or "left"
	    
    txt.undo_limit = txt.undo_limit or 20

    txt.undo_states = {}
    txt.redo_states = {}

    txt.wnd_pos = 0
	txt.caret = 0
	txt.sel_s, txt.sel_e = nil, nil

    txt.char_h, txt.wnd_h, txt.wnd_w, txt.char_w = nil, nil, nil, nil

	txt.focus = false

	txt.blink = 0    

	GUI.redraw_z(txt.z)

	setmetatable(txt, self)
	self.__index = self
	return txt

end


function GUI.Textbox:init()
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
	self.buff = GUI.get_buffer()
	
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*w, h)
	
	GUI.set_color("elm_bg")
	gfx.rect(0, 0, 2*w, h, 1)
	
	GUI.set_color("elm_frame")
	gfx.rect(0, 0, w, h, 0)
	
	GUI.set_color("elm_fill")
	gfx.rect(w, 0, w, h, 0)
	gfx.rect(w + 1, 1, w - 2, h - 2, 0)
	
	
end


function GUI.Textbox:draw()
	
	-- Some values can't be set in :init() because the window isn't
	-- open yet - measurements won't work.
	if not self.wnd_w then self:wnd_recalc() end
    
	if self.caption and self.caption ~= "" then self:draw_caption() end
	
	-- Blit the textbox frame, and make it brighter if focused.
	gfx.blit(self.buff, 1, 0, (self.focus and self.w or 0), 0, 
            self.w, self.h, self.x, self.y)

    if self.retval ~= "" then self:draw_text() end

	if self.focus then

		if self.sel_s then self:draw_selection() end
		if self.show_caret then self:draw_caret() end
		
	end
    
    self:draw_gradient()    
	
end


function GUI.Textbox:val(newval)
	
	if newval then
		self.retval = tostring(newval)
		self:redraw()		
	else
		return self.retval
	end
    
end


-- Just for making the caret blink
function GUI.Textbox:on_update()
	
	if self.focus then
	
		if self.blink == 0 then
			self.show_caret = true
			self:redraw()
		elseif self.blink == math.floor(GUI.txt_blink_rate / 2) then
			self.show_caret = false
			self:redraw()
		end
		self.blink = (self.blink + 1) % GUI.txt_blink_rate

	end
	
end

-- Make sure the box highlight goes away
function GUI.Textbox:lost_focus()
    
    self:redraw()
    
end



------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.Textbox:on_mouse_down()

    self.caret = self:get_caret(GUI.mouse.x)
    
    -- Reset the caret so the visual change isn't laggy
    self.blink = 0
    
    -- Shift+click to select text
    if GUI.mouse.cap & 8 == 8 and self.caret then
        
        self.sel_s, self.sel_e = self.caret, self.caret
        
    else
    
        self.sel_s, self.sel_e = nil, nil
        
    end
    
    self:redraw()
	
end


function GUI.Textbox:on_double_click()
	
	self:select_word()
    
end


function GUI.Textbox:on_drag()
	
	self.sel_s = self:get_caret(GUI.mouse.ox, GUI.mouse.oy)
    self.sel_e = self:get_caret(GUI.mouse.x, GUI.mouse.y)
    
	self:redraw()	
    
end


function GUI.Textbox:on_type()
	
	local char = GUI.char

    -- Navigation keys, Return, clipboard stuff, etc
    if self.keys[char] then
        
        local shift = GUI.mouse.cap & 8 == 8
        
        if shift and not self.sel then
            self.sel_s = self.caret
        end
        
        -- Flag for some keys (clipboard shortcuts) to skip
        -- the next section
        local bypass = self.keys[char](self)
        
        if shift and char ~= GUI.chars.BACKSPACE then
            
            self.sel_e = self.caret
            
        elseif not bypass then
        
            self.sel_s, self.sel_e = nil, nil
        
        end
        
    -- Typeable chars
    elseif GUI.clamp(32, char, 254) == char then
    
        if self.sel_s then self:delete_selection() end
        
        self:insert_char(char)

    end
    self:window_to_caret()
    
    -- Make sure no functions crash because they got a type==number
    self.retval = tostring(self.retval)
    
    -- Reset the caret so the visual change isn't laggy
    self.blink = 0
    
end


function GUI.Textbox:on_wheel(inc)
   
   local len = string.len(self.retval)
   
   if len <= self.wnd_w then return end
   
   -- Scroll right/left
   local dir = inc > 0 and 3 or -3
   self.wnd_pos = GUI.clamp(0, self.wnd_pos + dir, len + 2 - self.wnd_w)
   
   self:redraw()    
    
end




------------------------------------
-------- Drawing methods -----------
------------------------------------

	
function GUI.Textbox:draw_caption()
    
    local caption = self.caption
    
    GUI.set_font(self.font_a)
    
    local str_w, str_h = gfx.measurestr(caption)

    if self.cap_pos == "left" then
        gfx.x = self.x - str_w - self.pad
        gfx.y = self.y + (self.h - str_h) / 2    
    
    elseif self.cap_pos == "top" then
        gfx.x = self.x + (self.w - str_w) / 2
        gfx.y = self.y - str_h - self.pad
    
    elseif self.cap_pos == "right" then
        gfx.x = self.x + self.w + self.pad
        gfx.y = self.y + (self.h - str_h) / 2
    
    elseif self.cap_pos == "bottom" then
        gfx.x = self.x + (self.w - str_w) / 2
        gfx.y = self.y + self.h + self.pad
    
    end
    
    GUI.txt_bg(caption, self.bg)
    
    if self.shadow then 
        GUI.txt_shadow(caption, self.color, "shadow") 
    else
        GUI.set_color(self.color)
        gfx.drawstr(caption)
    end

end


function GUI.Textbox:draw_text()

	GUI.set_color(self.color)
	GUI.set_font(self.font_b)

    local str = string.sub(self.retval, self.wnd_pos + 1)

    -- I don't think self.pad should affect the text at all. Looks weird,
    -- messes with the amount of visible text too much.
	gfx.x = self.x + 4 -- + self.pad
	gfx.y = self.y + (self.h - gfx.texth) / 2
    local r = gfx.x + self.w - 8 -- - 2*self.pad
    local b = gfx.y + gfx.texth
    
	gfx.drawstr(str, 0, r, b)
    
end


function GUI.Textbox:draw_caret()
    
    local caret_wnd = self:adjust_to_window(self.caret)

    if caret_wnd then

        GUI.set_color("txt")
        
        gfx.rect(   self.x + self.pad + (caret_wnd * self.char_w),
                    self.y + self.pad,
                    self.insert_caret and self.char_w or 2,
                    self.char_h - 2)
                    
    end
    
end


function GUI.Textbox:draw_selection()

    local x, w
    
    GUI.set_color("elm_fill")
    gfx.a = 0.5
    gfx.mode = 1    
    
    local s, e = self.sel_s, self.sel_e
    
    if e < s then s, e = e, s end


    local x = GUI.clamp(self.wnd_pos, s, self:wnd_right())
    local w = GUI.clamp(x, e, self:wnd_right()) - x

    if self:selection_visible(x, w) then
        
        -- Convert from char-based coords to actual pixels
        x = self.x + self.pad + (x - self.wnd_pos) * self.char_w
        
        y = self.y + self.pad

        w = w * self.char_w
        w = math.min(w, self.x + self.w - x - self.pad)

        h = self.char_h
        
        gfx.rect(x, y, w, h, true)
        
    end    
        
    gfx.mode = 0
    
	-- Later calls to GUI.color should handle this, but for
	-- some reason they aren't always.    
    gfx.a = 1
    
end


function GUI.Textbox:draw_gradient()
    
    local left, right = self.wnd_pos > 0, self.wnd_pos < (string.len(self.retval) - self.wnd_w + 2)
    if not (left or right) then return end
    
    local x, y, w, h = self.x, self.y, self.w, self.h
    local fade_w = 12

    GUI.set_color("elm_bg")
    for i = 0, fade_w do
    
        gfx.a = i/fade_w
        
        -- Left
        if left then
            local x = x + 2 + fade_w - i
            gfx.line(x, y + 2, x, y + h - 4)
        end
        
        -- Right
        if right then
            local x = x + w - 3 - fade_w + i
            gfx.line(x, y + 2, x, y + h - 4)
        end
        
    end
    
end




------------------------------------
-------- Selection methods ---------
------------------------------------


-- Make sure at least part of the selection is visible
function GUI.Textbox:selection_visible(x, w)
    
	return 		w > 0                   -- Selection has width,
			and x + w > self.wnd_pos    -- doesn't end to the left
            and x < self:wnd_right()    -- and doesn't start to the right
    
end


function GUI.Textbox:select_all()
    
    self.sel_s = 0
    self.caret = 0
    self.sel_e = string.len(self.retval)
    
end


function GUI.Textbox:select_word()
    
    local str = self.retval
    
    if not str or str == "" then return 0 end
    
    self.sel_s = string.find( str:sub(1, self.caret), "%s[%S]+$") or 0
    self.sel_e = (      string.find( str, "%s", self.sel_s + 1)
                    or  string.len(str) + 1)
                - (self.wnd_pos > 0 and 2 or 1) -- Kludge, fixes length issues

end


function GUI.Textbox:delete_selection()   

    if not (self.sel_s and self.sel_e) then return 0 end

    self:store_undo_state()

    local s, e = self.sel_s, self.sel_e
        
    if s > e then
        s, e = e, s
    end
    
    self.retval =   string.sub(self.retval or "", 1, s)..
                    string.sub(self.retval or "", e + 1)
    
    self.caret = s
    
    self.sel_s, self.sel_e = nil, nil
    self:window_to_caret()
    
    
end


function GUI.Textbox:get_selected_text()
    
    local s, e= self.sel_s, self.sel_e
    
    if s > e then s, e = e, s end
    
    return string.sub(self.retval, s + 1, e)    
    
end


function GUI.Textbox:to_clipboard(cut)
    
    if self.sel_s and self:SWS_clipboard() then
        
        local str = self:get_selected_text()
        reaper.CF_SetClipboard(str)
        if cut then self:delete_selection() end
        
    end   
    
end


function GUI.Textbox:from_clipboard()
    
    if self:SWS_clipboard() then
        
        -- reaper.SNM_CreateFastString( str )
        -- reaper.CF_GetClipboardBig( output )
        local fast_str = reaper.SNM_CreateFastString("")
        local str = reaper.CF_GetClipboardBig(fast_str)
        reaper.SNM_DeleteFastString(fast_str)
        
        self:insert_string(str, true)

    end   
    
end



------------------------------------
-------- Window/pos helpers --------
------------------------------------


function GUI.Textbox:wnd_recalc()
    
    GUI.set_font(self.font_b)
    
    self.char_h = gfx.texth
    self.char_w = gfx.measurestr("_")
    self.wnd_w = math.floor(self.w / self.char_w)
    
end


function GUI.Textbox:wnd_right()
    
   return self.wnd_pos + self.wnd_w 
    
end


-- See if a given position is in the visible window
-- If so, adjust it from absolute to window-relative
-- If not, returns nil
function GUI.Textbox:adjust_to_window(x)
    
    return ( GUI.clamp(self.wnd_pos, x, self:wnd_right() - 1) == x )
        and x - self.wnd_pos
        or nil

end


function GUI.Textbox:window_to_caret()
    
    if self.caret < self.wnd_pos + 1 then
        self.wnd_pos = math.max(0, self.caret - 1)
    elseif self.caret > (self:wnd_right() - 2) then
        self.wnd_pos = self.caret + 2 - self.wnd_w
    end
    
end


function GUI.Textbox:get_caret(x)

    x = math.floor(  ((x - self.x) / self.w) * self.wnd_w) + self.wnd_pos
    return GUI.clamp(0, x, string.len(self.retval or ""))

end




------------------------------------
-------- Char/string helpers -------
------------------------------------


function GUI.Textbox:insert_string(str, move_caret)

    self:store_undo_state()
    
    str = self:sanitize_text(str)
    
    if self.sel_s then self:delete_selection() end
    
    local s = self.caret
    
    local pre, post =   string.sub(self.retval or "", 1, s),
                        string.sub(self.retval or "", s + 1)
                        
    self.retval = pre .. tostring(str) .. post
    
    if move_caret then self.caret = self.caret + string.len(str) end
    
end


function GUI.Textbox:insert_char(char)
    
    self:store_undo_state()
    
    local a, b = string.sub(self.retval, 1, self.caret), 
                 string.sub(self.retval, self.caret + (self.insert_caret and 2 or 1))
                
    self.retval = a..string.char(char)..b
    self.caret = self.caret + 1
    
end


function GUI.Textbox:caret_to_end()
    
   return string.len(self.retval or "")
    
end


-- Replace any characters that we're unable to reproduce properly
function GUI.Textbox:sanitize_text(str)

    str = tostring(str)
    str = str:gsub("\t", "    ")
    str = str:gsub("[\n\r]", " ")
    return str

end


function GUI.Textbox:ctrl_char(func, ...)
    
    if GUI.mouse.cap & 4 == 4 then
        func(self, ... and table.unpack({...}))
        
        -- Flag to bypass the "clear selection" logic in :on_type()        
        return true
        
    else
        self:insert_char(GUI.char)        
    end    

end

-- Non-typing key commands
-- A table of functions is more efficient to access than using really
-- long if/then/else structures.
GUI.Textbox.keys = {
    
    [GUI.chars.LEFT] = function(self)
       
        self.caret = math.max( 0, self.caret - 1)
        
    end,
    
    [GUI.chars.RIGHT] = function(self)
        
        self.caret = math.min( string.len(self.retval), self.caret + 1 )
        
    end,
    
    [GUI.chars.UP] = function(self)
    
        self.caret = 0
        
    end,
    
    [GUI.chars.DOWN] = function(self)
        
        self.caret = string.len(self.retval)
        
    end,    
    
    [GUI.chars.BACKSPACE] = function(self)
        
        self:store_undo_state()
        
        if self.sel_s then
            
            self:delete_selection()
            
        else
        
        if self.caret <= 0 then return end
            
            local str = self.retval
            self.retval =   string.sub(str, 1, self.caret - 1)..
                            string.sub(str, self.caret + 1, -1)
            self.caret = math.max(0, self.caret - 1)
            
        end
        
    end,
    
    [GUI.chars.INSERT] = function(self)
        
        self.insert_caret = not self.insert_caret        
        
    end,

    [GUI.chars.DELETE] = function(self)
        
        self:store_undo_state()
        
        if self.sel_s then
            
            self:delete_selection()
            
        else
        
            local str = self.retval
            self.retval =   string.sub(str, 1, self.caret) ..
                            string.sub(str, self.caret + 2)
                            
        end
        
    end,
    
    [GUI.chars.RETURN] = function(self)
        
        self.focus = false
        self:lost_focus()
        self:redraw()

    end,
    
    [GUI.chars.HOME] = function(self)
        
        self.caret = 0
        
    end,
    
    [GUI.chars.END] = function(self)
        
        self.caret = string.len(self.retval)
        
    end,

    [GUI.chars.TAB] = function(self)
        
        GUI.tab_to_next(self)
        
    end,

	-- A -- Select All
	[1] = function(self)
		
		return self:ctrl_char(self.select_all)
		
	end,
	
	-- C -- Copy
	[3] = function(self)
		
		return self:ctrl_char(self.to_clipboard)
		
	end,
	
	-- V -- Paste
	[22] = function(self)
		
        return self:ctrl_char(self.from_clipboard)	
		
	end,
	
	-- X -- Cut
	[24] = function(self)
	
		return self:ctrl_char(self.to_clipboard, true)
		
	end,	
	
	-- Y -- Redo
	[25] = function (self)
		
		return self:ctrl_char(self.redo)
		
	end,
	
	-- Z -- Undo
	[26] = function (self)
		
		return self:ctrl_char(self.undo)		
		
	end


}




------------------------------------
-------- Misc. helpers -------------
------------------------------------


function GUI.Textbox:undo()
	
	if #self.undo_states == 0 then return end
	table.insert(self.redo_states, self:get_editor_state() )
	local state = table.remove(self.undo_states)

    self.retval = state.retval
	self.caret = state.caret
	
	self:window_to_caret()
	
end


function GUI.Textbox:redo()
	
	if #self.redo_states == 0 then return end
	table.insert(self.undo_states, self:get_editor_state() )
	local state = table.remove(self.redo_states)
    
	self.retval = state.retval
	self.caret = state.caret
	
	self:window_to_caret()
	
end


function GUI.Textbox:store_undo_state()

table.insert(self.undo_states, self:get_editor_state() )
	if #self.undo_states > self.undo_limit then table.remove(self.undo_states, 1) end
	self.redo_states = {}

end


function GUI.Textbox:get_editor_state()
	
	return { retval = self.retval, caret = self.caret }
	
end


-- See if we have a new-enough version of SWS for the clipboard functions
-- (v2.9.7 or greater)
function GUI.Textbox:SWS_clipboard()
	
	if GUI.SWS_exists then
		return true
	else
	
		reaper.ShowMessageBox(	"Clipboard functions require the SWS extension, v2.9.7 or newer."..
									"\n\nDownload the latest version at http://www.sws-extension.org/index.php",
									"Sorry!", 0)
		return false
	
	end
	
end