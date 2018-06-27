------------------------------------
-------- Text functions ------------
------------------------------------


--[[	Apply a font preset
	
	fnt			Font preset number
				or
				A preset table -> GUI.set_font({"Arial", 10, "i"})
	
]]--
GUI.set_font = function (fnt)
	
	local font, size, str = table.unpack( type(fnt) == "table" 
                                            and fnt 
                                            or  GUI.fonts[fnt])
	
	-- Different OSes use different font sizes, for some reason
	-- This should give a roughly equal size on Mac
	if string.find(reaper.GetOS(), "OSX") then
		size = math.floor(size * 0.7)
	end
	
	-- Cheers to Justin and Schwa for this
	local flags = 0
	if str then
		for i = 1, str:len() do 
			flags = flags * 256 + string.byte(str, i) 
		end 	
	end
	
	gfx.setfont(1, font, size, flags)

end


--[[	Prepares a table of character widths
	
	Iterates through all of the GUI.fonts[] presets, storing the widths
	of every printable ASCII character in a table. 
	
	Accessable via:		GUI.txt_width[font_num][char_num]
	
	- Requires a window to have been opened in Reaper
	
	- 'get_txt_width' and 'word_wrap' will automatically run this
	  if it hasn't been run already; it may be rather clunky to use
	  on demand depending on what your script is doing, so it's
	  probably better to run this immediately after initiliazing
	  the window and then have the width table ready to use.
]]--

GUI.init_txt_width = function ()

	GUI.txt_width = {}
	local arr
	for k in pairs(GUI.fonts) do
			
		GUI.set_font(k)
		GUI.txt_width[k] = {}
		arr = {}
		
		for i = 1, 255 do
			
			arr[i] = gfx.measurechar(i)
			
		end	
		
		GUI.txt_width[k] = arr
		
	end
	
end


-- Returns the total width (in pixels) for a given string and font
-- (as a GUI.fonts[] preset number or name)
-- Most of the time it's simpler to use gfx.measurestr(), but scripts 
-- with a lot of text should use this instead - it's 10-12x faster.
GUI.get_txt_width = function (str, font)
	
	if not GUI.txt_width then GUI.init_txt_width() end 

	local widths = GUI.txt_width[font]
	local w = 0
	for i = 1, string.len(str) do

		w = w + widths[		string.byte(	string.sub(str, i, i)	) ]

	end

	return w

end


-- Measures a string to see how much of it will it in the given width,
-- then returns both the trimmed string and the excess
GUI.fit_txt_width = function (str, font, w)
    
    local len = string.len(str)
    
    -- Assuming 'i' is the narrowest character, get an upper limit
    local max_end = math.floor( w / GUI.txt_width[font][string.byte("i")] )

    for i = max_end, 1, -1 do
       
        if GUI.get_txt_width( string.sub(str, 1, i), font ) < w then
           
           return string.sub(str, 1, i), string.sub(str, i + 1)
           
        end
        
    end
    
    -- Worst case: not even one character will fit
    -- If this actually happens you should probably rethink your choices in life.
    return "", str

end


--[[	Returns 'str' wrapped to fit a given pixel width
	
	str		String. Can include line breaks/paragraphs; they should be preserved.
	font	Font preset number
	w		Pixel width
	indent	Number of spaces to indent the first line of each paragraph
			(The algorithm skips tab characters and leading spaces, so
			use this parameter instead)
	
	i.e.	Blah blah blah blah		-> indent = 2 ->	  Blah blah blah blah
			blah blah blah blah							blah blah blah blah

	
	pad		Indent wrapped lines by the first __ characters of the paragraph
			(For use with bullet points, etc)
			
	i.e.	- Blah blah blah blah	-> pad = 2 ->	- Blah blah blah blah
			blah blah blah blah				  	 	  blah blah blah blah
	
				
	This function expands on the "greedy" algorithm found here:
	https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap#Algorithm
				
]]--
GUI.word_wrap = function (str, font, w, indent, pad)
	
	if not GUI.txt_width then GUI.init_txt_width() end
	
	local ret_str = {}

	local w_left, w_word
	local space = GUI.txt_width[font][string.byte(" ")]
	
	local new_para = indent and string.rep(" ", indent) or 0
	
	local w_pad = pad   and GUI.get_txt_width( string.sub(str, 1, pad), font ) 
                        or 0
	local new_line = "\n"..string.rep(" ", math.floor(w_pad / space)	)
	
	
	for line in string.gmatch(str, "([^\n\r]*)[\n\r]*") do
		
		table.insert(ret_str, new_para)
		
		-- Check for leading spaces and tabs
		local leading, line = string.match(line, "^([%s\t]*)(.*)$")	
		if leading then table.insert(ret_str, leading) end
		
		w_left = w
		for word in string.gmatch(line,  "([^%s]+)") do
	
			w_word = GUI.get_txt_width(word, font)
			if (w_word + space) > w_left then
				
				table.insert(ret_str, new_line)
				w_left = w - w_word
				
			else
			
				w_left = w_left - (w_word + space)
				
			end
			
			table.insert(ret_str, word)
			table.insert(ret_str, " ")
			
		end
		
		table.insert(ret_str, "\n")
		
	end
	
	table.remove(ret_str, #ret_str)
	ret_str = table.concat(ret_str)
	
	return ret_str
			
end


-- Draw the given string of the first color with a shadow 
-- of the second color (at 45' to the bottom-right)
GUI.txt_shadow = function (str, col1, col2)
	
	local x, y = gfx.x, gfx.y
	
	GUI.set_color(col2 or "shadow")
	for i = 1, GUI.shadow_dist do
		gfx.x, gfx.y = x + i, y + i
		gfx.drawstr(str)
	end
	
	GUI.set_color(col1)
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end


-- Draws a string using the given text and outline color presets
GUI.txt_outline = function (str, col1, col2)

	local x, y = gfx.x, gfx.y
	
	GUI.set_color(col2)
	
	gfx.x, gfx.y = x + 1, y + 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x - 1, y + 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x - 1, y - 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x + 1, y - 1
	gfx.drawstr(str)
	
	GUI.set_color(col1)
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end


--[[	Draw a background rectangle for the given string
	
	A solid background is necessary for blitting z layers
	on their own; antialiased text with a transparent background
	looks like complete shit. This function draws a rectangle 2px
	larger than your text on all sides.
	
	Call with your position, font, and color already set:
	
	gfx.x, gfx.y = self.x, self.y
	GUI.set_font(self.font)
	GUI.set_color(self.col)
	
	GUI.txt_bg(self.text)
	
	gfx.drawstr(self.text)
	
	Also accepts an optional background color:
	GUI.txt_bg(self.text, "elm_bg")
	
]]--
GUI.txt_bg = function (str, col)
	
	local x, y = gfx.x, gfx.y
	local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a
	
	col = col or "wnd_bg"
	
	GUI.set_color(col)
	
	local w, h = gfx.measurestr(str)
	w, h = w + 4, h + 4
		
	gfx.rect(gfx.x - 2, gfx.y - 2, w, h, true)
	
	gfx.x, gfx.y = x, y
	
	gfx.set(r, g, b, a)	
	
end



