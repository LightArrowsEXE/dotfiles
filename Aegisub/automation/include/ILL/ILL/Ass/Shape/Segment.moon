import Math from require "ILL.ILL.Math"
import Point from require "ILL.ILL.Ass.Shape.Point"

class Segment

	-- create a new Segment object
	new: (@a = Point!, @b = Point!) =>

	-- gets the value of X given a time on a segment
	getXatTime: (t) => (1 - t) * @a.x + t * @b.x

	-- gets the value of Y given a time on a segment
	getYatTime: (t) => (1 - t) * @a.y + t * @b.y

	-- gets the value of Point given a time on a segment
	getPTatTime: (t) =>
		x = @getXatTime t
		y = @getYatTime t
		return Point x, y

	-- flattens the segment
	flatten: (len = @getLength!, reduce = 1) =>
		len = math.floor len / reduce + 0.5
		points = {Point @a.x, @a.y}
		for i = 1, len - 1
			table.insert points, @getPTatTime i / len
		table.insert points, Point @b.x, @b.y
		return points

	-- splits the segment in two
	split: (t = 0.5) =>
		{:a, :b} = @
		c = a\lerp b, t
		return {
			Segment a, c
			Segment c, b
		}

	-- gets the normalized tangent given a time on a segment
	getNormalized: (t, inverse) =>
		t = Math.clamp t, 0, 1
		p = @getPTatTime t
		d = Point!
		d.x = @b.x - p.x
		d.y = @b.y - p.y
		with d
			if inverse
				.x, .y = .y, -.x
			else
				.x, .y = -.y, .x
		mag = d\vecMagnitude!
		tan = Point d.x / mag, d.y / mag
		return tan, p, t

	-- gets the real length of the segment through time
	getLength: (t = 1) => t * @a\distance @b

	-- converts a segment to a bezier curve
	lineToBezier: =>
		a = @a\clone!
		b = Point (2 * @a.x + @b.x) / 3, (2 * @a.y + @b.y) / 3
		c = Point (@a.x + 2 * @b.x) / 3, (@a.y + 2 * @b.y) / 3
		d = @b\clone!
		a.id, b.id, c.id, d.id = "l", "b", "b", "b"
		return a, b, c, d
	
	reverse: =>
		a2, b2 = @a\clone!, @b\clone!
		@a, @b = b2, a2

{:Segment}