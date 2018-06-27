------------------------------------
-------- Math/trig functions -------
------------------------------------


-- Round a number to the nearest integer (or optional decimal places)
GUI.round = function (num, places)

	if not places then
		return num > 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
	else
		places = 10^places
		return num > 0 and math.floor(num * places + 0.5) 
                        or math.ceil(num * places - 0.5) / places
	end
	
end


-- Returns 'val', rounded to the nearest multiple of 'snap'
GUI.nearest_multiple = function (val, snap)
    
    local int, frac = math.modf(val / snap)
    return (math.floor( frac + 0.5 ) == 1 and int + 1 or int) * snap
    
end



-- Make sure num is between min and max
-- I think it will return the correct value regardless of what
-- order you provide the values in.
GUI.clamp = function (num, min, max)
        
	if min > max then min, max = max, min end
	return math.min(math.max(num, min), max)
    
end


-- Returns an ordinal string (i.e. 30 --> 30th)
GUI.ordinal = function (num)
	
	rem = num % 10
	num = GUI.round(num)
	if num == 1 then
		str = num.."st"
	elseif rem == 2 then
		str = num.."nd"
	elseif num == 13 then
		str = num.."th"
	elseif rem == 3 then
		str = num.."rd"
	else
		str = num.."th"
	end
	
	return str
	
end


--[[ 
	Takes an angle in radians (omit Pi) and a radius, returns x, y
	Will return coordinates relative to an origin of (0,0), or absolute
	coordinates if an origin point is specified
]]--
GUI.polar_to_cart = function (angle, radius, ox, oy)
	
	local angle = angle * GUI.pi
	local x = radius * math.cos(angle)
	local y = radius * math.sin(angle)

	
	if ox and oy then x, y = x + ox, y + oy end

	return x, y
	
end


--[[
	Takes cartesian coords, with optional origin coords, and returns
	an angle (in radians) and radius. The angle is given without reference
	to Pi; that is, pi/4 rads would return as simply 0.25
]]--
GUI.cart_to_polar = function (x, y, ox, oy)
	
	local dx, dy = x - (ox or 0), y - (oy or 0)
	
	local angle = math.atan(dy, dx) / GUI.pi
	local r = math.sqrt(dx * dx + dy * dy)

	return angle, r
	
end


-- Why does Lua not have an operator for this?
GUI.xor = function(a, b)
   
   return (a or b) and not (a and b)
    
end