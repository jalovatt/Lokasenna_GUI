--[[	Lokasenna_GUI - Options class
	
    This file provides two separate element classes:
    
    Radio       A list of options from which the user can only choose one at a time.
    Checklist   A list of options from which the user can choose any, all or none.
    
    Both classes take the same parameters on creation, and offer the same parameters
    afterward - their usage only differs when it comes to their respective :val methods.
    
    



	Adapted from eugen2777's simple GUI template.
	
	---- User parameters ----
	
	(name, z, x, y, w, h, caption, opts[, dir, pad])
	
Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
caption			Element title. Feel free to just use a blank string: ""
opts			Accepts either a table* or a comma-separated string of options.

				Options can be skipped to create a gap in the list by using "__":
				
				opts = "Alice,Bob,Charlie,__,Edward,Francine"
				->
				Alice
				Bob
				Charlie
				
				Edward
				Francine


                * Must be indexed contiguously, starting from 1.

Optional:
dir				"h"		Options will extend to the right, with labels above them
				"v"		Options will extend downward, with labels to their right
pad				Separation in px between options. Defaults to 4.


Additional:
bg				Color to be drawn underneath the caption. Defaults to "wnd_bg"
frame			Boolean. Draw a frame around the options.
size			Width of the unfilled options in px. Defaults to 20.
				* Changing this might mess up the spacing *
col_txt			Text color
col_fill		Filled option color
font_a			List title font
font_b			List option font
shadow			Boolean. Draw a shadow under the text? Defaults to true.
swap			If dir = "h", draws the option labels below them rather than above
						 "v", shifts the options over and draws the option labels 
                              to the left rather than the right.


Extra methods:


    Radio

GUI.Val()		Returns the current option, numbered from 1.
GUI.Val(new)	Sets the current option, numbered from 1.


    Checklist
    
GUI.Val()		Returns a table of boolean values for each option. Indexed from 1.
GUI.Val(new)	Accepts a table of boolean values for each option. Indexed from 1.

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


local Option = GUI.Element:new()

function Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
	local option = {}
	
	option.name = name
	option.type = "Option"
	
	option.z = z
	GUI.redraw_z[z] = true	
	
	option.x, option.y, option.w, option.h = x, y, w, h

	option.caption = caption

	option.frame = true
	option.bg = "wnd_bg"
    
	option.dir = dir or "v"
	option.pad = pad or 4
        
	option.col_txt = "txt"
	option.col_fill = "elm_fill"

	option.font_a = 2
	option.font_b = 3
	
	option.shadow = true
	
    option.swap = false
    
	-- Size of the option bubbles
	option.opt_size = 20
	
	-- Parse the string of options into a table
	option.optarray = {}
    
    if type(opts) == "table" then
        
        for i = 1, #opts do
            option.optarray[i] = opts[i]
        end
        
    else
    
        local tempidx = 1
        for word in string.gmatch(opts, '([^,]+)') do
            option.optarray[tempidx] = word
            tempidx = tempidx + 1
        end
        
    end

	setmetatable(option, self)
    self.__index = self 
    return option
    
end


function Option:init()
	
    -- Make sure we're not trying to use the base class.
    if self.type == "Option" then
        reaper.ShowMessageBox(  "'"..self.name.."' was initialized as an Option element,"..
                                "but Option doesn't do anything on its own!",
                                "GUI Error", 0)
        
        GUI.quit = true
        return
        
    end
        
	self.buff = self.buff or GUI.GetBuffer()
		
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*self.opt_size + 4, 2*self.opt_size + 2)
	
    
    self:initoptions()
	
    
	if self.caption ~= "" then
		GUI.font(self.font_a)		
		local str_w, str_h = gfx.measurestr(self.caption)
		self.cap_h = 0.5*str_h
		self.cap_x = self.x + (self.w - str_w) / 2	
	else
		self.cap_h = 0
		self.cap_x = 0
	end
	
end


function Option:draw()
	
	if self.frame then
		GUI.color("elm_frame")
		gfx.rect(self.x, self.y, self.w, self.h, 0)
	end

    if self.caption and self.caption ~= "" then self:drawcaption() end

    self:drawoptions()

end




------------------------------------
-------- Input helpers -------------
------------------------------------




function Option:getmouseopt()
    
    local len = #self.optarray
    
	-- See which option it's on
	local mouseopt = self.dir == "h" 	
                    and (GUI.mouse.x - (self.x + self.pad))
					or	(GUI.mouse.y - (self.y + self.cap_h + 1.5*self.pad) )
	mouseopt = mouseopt / ((self.opt_size + self.pad) * len)
	mouseopt = GUI.clamp( math.floor(mouseopt * len) + 1 , 1, len )
    
    return mouseopt
    
end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Option:drawcaption()
    
    GUI.font(self.font_a)
    
    gfx.x = self.cap_x
    gfx.y = self.y - self.cap_h
    
    GUI.text_bg(self.caption, self.bg)
    
    GUI.shadow(self.caption, self.col_txt, "shadow")
    
end


function Option:drawoptions()

    local x, y, w, h = self.x, self.y, self.w, self.h
    
    local horz = self.dir == "h"
	local pad = self.pad
    
    -- Bump everything down for the caption
    y = y + self.cap_h + 1.5 * pad 

    -- Bump the options down more for horizontal options
    -- with the text on top
	if horz and self.caption ~= "" and not self.swap then
        y = y + self.cap_h + 2*pad 
    end

	local size = self.opt_size
    
    local adj = size + pad

    local str, opt_x, opt_y

	for i = 1, #self.optarray do
	
		str = self.optarray[i]
		if str ~= "__" then
		        
            opt_x = x + (horz   and (i - 1) * adj + pad
                                or  (self.swap  and (w - adj - 1) 
                                                or   pad))
                                                
            opt_y = y + (i - 1) * (horz and 0 or adj)
                
			-- Draw the option bubble
            self:drawoption(opt_x, opt_y, size, self:isoptselected(i))

            self:drawvalue(opt_x,opt_y, size, str)
            
		end
		
	end
	
end


function Option:drawoption(opt_x, opt_y, size, selected)
    
    gfx.blit(   self.buff, 1,  0,  
                selected and (size + 3) or 1, 1, 
                size + 1, size + 1, 
                opt_x, opt_y)

end


function Option:drawvalue(opt_x, opt_y, size, str)

	GUI.font(self.font_b) 

    local str_w, str_h = gfx.measurestr(str)
    
    if self.dir == "h" then
        
        gfx.x = opt_x + (size - str_w) / 2
        gfx.y = opt_y + (self.swap and (size + 4) or -size)

    else
    
        gfx.x = opt_x + (self.swap and -(str_w + 8) or 1.5*size)
        gfx.y = opt_y + (size - str_h) / 2
        
    end

    GUI.text_bg(str, self.bg)
    if #self.optarray == 1 or self.shadow then
        GUI.shadow(str, self.col_txt, "shadow")
    else
        GUI.color(self.col_txt)
        gfx.drawstr(str)
    end

end




------------------------------------
-------- Radio methods -------------
------------------------------------


GUI.Radio = {}
setmetatable(GUI.Radio, {__index = Option})

function GUI.Radio:new(name, z, x, y, w, h, caption, opts, dir, pad)

    local radio = Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
    radio.type = "Radio"
    
    radio.retval, radio.state = 1, 1
    
    setmetatable(radio, self)
    self.__index = self
    return radio
    
end


function GUI.Radio:initoptions()

	local r = self.opt_size / 2

	-- Option bubble
	GUI.color(self.bg)
	gfx.circle(r + 1, r + 1, r + 2, 1, 0)
	gfx.circle(3*r + 3, r + 1, r + 2, 1, 0)
	GUI.color("elm_frame")
	gfx.circle(r + 1, r + 1, r, 0)
	gfx.circle(3*r + 3, r + 1, r, 0)
	GUI.color(self.col_fill)
	gfx.circle(3*r + 3, r + 1, 0.5*r, 1)


end


function GUI.Radio:val(newval)
	
	if newval then
		self.retval = newval
		self.state = newval
		GUI.redraw_z[self.z] = true		
	else
		return self.retval
	end	
	
end


function GUI.Radio:onmousedown()
	
	self.state = self:getmouseopt()

	GUI.redraw_z[self.z] = true

end


function GUI.Radio:onmouseup()
		
	-- Set the new option, or revert to the original if the cursor 
    -- isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval	
	end

	GUI.redraw_z[self.z] = true

end


function GUI.Radio:ondrag() 

	self:onmousedown()

	GUI.redraw_z[self.z] = true

end


function GUI.Radio:onwheel()
	
	self.state = GUI.round(self.state +     (self.dir == "h" and 1 or -1) 
                                        *    GUI.mouse.inc)
                                        
	if self.state < 1 then self.state = 1 end
	if self.state > #self.optarray then self.state = #self.optarray end
	
	self.retval = self.state

	GUI.redraw_z[self.z] = true

end


function GUI.Radio:isoptselected(opt)
    
   return opt == self.state 
    
end




------------------------------------
-------- Checklist methods ---------
------------------------------------


GUI.Checklist = {}
setmetatable(GUI.Checklist, {__index = Option})

function GUI.Checklist:new(name, z, x, y, w, h, caption, opts, dir, pad)

    local checklist = Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
    checklist.type = "Checklist"
    
    checklist.optsel = {}
    
    setmetatable(checklist, self)
    self.__index = self
    return checklist
    
end


function GUI.Checklist:initoptions()

	local size = self.opt_size

	-- Option bubble
	GUI.color("elm_frame")
	gfx.rect(1, 1, size, size, 0)
    gfx.rect(size + 3, 1, size, size, 0)
	
	GUI.color(self.col_fill)
	gfx.rect(size + 3 + 0.25*size, 1 + 0.25*size, 0.5*size, 0.5*size, 1)

end


function GUI.Checklist:val(newval)
	
	if new then
		if type(new) == "table" then
			for i = 1, #new do
				self.optsel[i] = new[i]
			end
			GUI.redraw_z[self.z] = true	
		end
	else
		return self.optsel
	end
	
end


function GUI.Checklist:onmouseup()
		
    local mouseopt = self:getmouseopt()
	
	self.optsel[mouseopt] = not self.optsel[mouseopt] 

	GUI.redraw_z[self.z] = true

end


function GUI.Checklist:isoptselected(opt)
   
   return self.optsel[opt]
    
end