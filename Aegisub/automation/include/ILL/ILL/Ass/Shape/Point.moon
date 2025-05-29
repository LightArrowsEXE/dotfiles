import Math from require "ILL.ILL.Math"

class Point

	-- Create a new Point object
	new: (@x = 0, @y = 0, @id = "l") =>

	-- Returns a copy of the point.
	clone: => Point @x, @y, @id

	-- Returns the subtraction of the supplied value to both coordinates of the point as a new point.
	-- The object itself is not modified.
	add: (point) =>
		if type(point) == "number"
			Point @x + point, @y + point
		return Point @x + point.x, @y + point.y

	-- Returns the subtraction of the supplied point to the point as a new point.
	-- The object itself is not modified.
	subtract: (point) =>
		if type(point) == "number"
			Point @x - point, @y - point
		return Point @x - point.x, @y - point.y

	-- Returns the multiplication of the supplied value to both coordinates of the point as a new point.
	-- The object itself is not modified.
	multiply: (point) =>
		if type(point) == "number"
			return Point @x * point, @y * point
		return Point @x * point.x, @y * point.y

	-- Returns the division of the supplied value to both coordinates of the point as a new point.
	-- The object itself is not modified!
	divide: (point) =>
		if type(point) == "number"
			return Point @x / point, @y / point
		return Point @x / point.x, @y / point.y

	-- Change the direction of the vector
	negate: => Point -@x, -@y

	-- Checks if the points are equal
	equals: (point) => @x == point.x and @y == point.y

	-- Move the object according the given params.
	move: (x, y) =>
		@x += x
		@y += y
		return @

	-- Rotate the object according the given params.
	rotate: (angle, c = Point!) =>
		x_rel = @x - c.x
		y_rel = @y - c.y
		@x = x_rel * math.cos(angle) - y_rel * math.sin(angle) + c.x
		@y = x_rel * math.sin(angle) + y_rel * math.cos(angle) + c.y 
		return @

	-- Rotate the object according the given params.
	rotatefrz: (angle) =>
		{:x, :y} = @
		angle = -math.rad(angle)
		@x = x * math.cos(angle) - y * math.sin(angle)
		@y = x * math.sin(angle) + y * math.cos(angle)
		return @

	-- Scale the object according the given params.
	scale: (hor, ver) =>
		@x *= hor / 100
		@y *= ver / 100
		return @

	-- Round the coordinates of the point
	round: (dec = 3) =>
		@x = Math.round @x, dec
		@y = Math.round @y, dec
		return @

	-- Linear interpolation between two points
	lerp: (point, t) =>
		x = (1 - t) * @x + t * point.x
		y = (1 - t) * @y + t * point.y
		return Point x, y

	-- Squared distance between two points
	sqDistance: (point) =>
		x = @x - point.x
		y = @y - point.y
		return x ^ 2 + y ^ 2

	-- Distance between two points
	distance: (point) =>
		sq = @sqDistance point
		return math.sqrt sq

	-- Angle between two points
	angle: (point = Point!) =>
		x = point.x - @x
		y = point.y - @y
		return math.atan2 y, x

	-- Returns the dot product of the point and another point.
	dot: (point) =>
		x = @x * point.x
		y = @y * point.y
		return x + y

	-- Returns the cross product of the point and another point.
	cross: (point) =>
		x = @x * point.y
		y = @y * point.x
		return x - y

	-- Calculates the length of the vector
	vecLength: => @x ^ 2 + @y ^ 2

	-- Calculates the magnitude of the vector
	vecMagnitude: =>
		length = @vecLength!
		return math.sqrt length

	-- Normalizes the coordinates of the vector
	vecNormalize: =>
		result = Point!
		length = @vecLength!
		if length != 0
			result.x = @x / length
			result.y = @y / length
		return result

	-- Scales the coordinates of the vector
	vecScale: (len) =>
		result = Point!
		length = @vecMagnitude!
		if length != 0
			result.x = @x * len / length
			result.y = @y * len / length
		return result

	-- Squared distance between a point and a segment
	sqSegDistance: (p1, p2) =>
		{:x, :y} = p1
		dx = p2.x - x
		dy = p2.y - y
		if dx != 0 or dy != 0
			t = ((@x - x) * dx + (@y - y) * dy) / (dx * dx + dy * dy)
			if t > 1
				x = p2.x
				y = p2.y
			elseif t > 0
				x += dx * t
				y += dy * t
		return @sqDistance Point x, y

	-- Distance between a point and a segment
	segDistance: (p1, p2) =>
		return math.sqrt @sqSegDistance p1, p2

	-- Returns the distance between the origin and the point
	hypot: =>
		if @x == 0 and @y == 0
			return 0
		ax, ay = math.abs(@x), math.abs(@y)
		px, py = math.max(ax, ay), math.min(ax, ay)
		return px * math.sqrt 1 + (py / px) ^ 2

	-- https://iquilezles.org/articles/ibilinear/
	-- Maps a point from XY coordinates to UV coordinates on a quadrilateral surface
	quadPT2UV: (a, b, c, d) =>
		e = Point b.x - a.x, b.y - a.y
		f = Point d.x - a.x, d.y - a.y
		g = Point a.x - b.x + c.x - d.x, a.y - b.y + c.y - d.y
		h = Point @x - a.x, @y - a.y

		k2 = g\cross(f)
		k1 = e\cross(f) + h\cross(g)
		k0 = h\cross(e)

		-- if edges are parallel, this is a linear equation
		if math.abs(k2) < 1e-3
			u = (h.x * k1 + f.x * k0) / (e.x * k1 - g.x * k0)
			v = -k0 / k1
			return Point u, v

		-- otherwise, it's a quadratic
		w = k1 * k1 - 4 * k0 * k2
		if w < 0
			return Point -1, -1
		w = math.sqrt w

		ik2 = 0.5 / k2
		v = (-k1 - w) * ik2
		u = (h.x - f.x * v) / (e.x + g.x * v)

		if u < 0 or u > 1 or v < 0 or v > 1
			v = (-k1 + w) * ik2
			u = (h.x - f.x * v) / (e.x + g.x * v)

		return Point u, v

	-- Does the inverse of quadPT2UV
	quadUV2PT: (a, b, c, d) =>
		{x: u, y: v} = @
		px = a.x + u * (b.x - a.x) + v * (d.x - a.x) + u * v * (a.x - b.x + c.x - d.x)
		py = a.y + u * (b.y - a.y) + v * (d.y - a.y) + u * v * (a.y - b.y + c.y - d.y)
		return Point px, py

{:Point}
