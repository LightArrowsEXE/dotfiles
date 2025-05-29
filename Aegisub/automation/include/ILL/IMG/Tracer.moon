ffi = require "ffi"
{:insert, :remove} = table

-- imagetracer.js version 1.2.6
-- Simple raster image tracer and vectorizer written in JavaScript.
-- andras@jankovics.net
-- */

-- /*

-- The Unlicense / PUBLIC DOMAIN

-- This is free and unencumbered software released into the public domain.

-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this software, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.

-- In jurisdictions that recognize copyright laws, the author or authors
-- of this software dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors. We intend this dedication to be an overt act of
-- relinquishment in perpetuity of all present and future rights to this
-- software under copyright law.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.

-- For more information, please refer to http://unlicense.org/
class Tracer

	versionnumber: "1.2.6"

	optionpresets: {
		default: {
			-- Tracing
			ltres: 1
			qtres: 1
			pathomit: 8
			rightangleenhance: true

			-- Color quantization
			colorsampling: 2
			numberofcolors: 16
			mincolorratio: 0
			colorquantcycles: 3

			-- Layering method
			layering: 0

			-- SVG rendering
			strokewidth: 1
			scale: 1
			roundcoords: 1

			-- Blur
			blurradius: 0
			blurdelta: 20
		}
		posterized1: {colorsampling: 0, numberofcolors: 2}
		posterized2: {numberofcolors: 4, blurradius: 5}
		curvy: {ltres: 0.01, rightangleenhance: false}
		sharp: {qtres: 0.01}
		detailed: {
			pathomit: 0
			roundcoords: 2
			ltres: 0.5
			qtres: 0.5
			numberofcolors: 64
		}
		smoothed: {blurradius: 5, blurdelta: 64}
		grayscale: {colorsampling: 0, colorquantcycles: 1, numberofcolors: 7}
		fixedpalette: {colorsampling: 0, colorquantcycles: 1, numberofcolors: 27}
		randomsampling1: {colorsampling: 1, numberofcolors: 8}
		randomsampling2: {colorsampling: 1, numberofcolors: 64}
		artistic1: {
			colorsampling: 0
			colorquantcycles: 1
			pathomit: 0
			blurradius: 5
			blurdelta: 64
			ltres: 0.01
			numberofcolors: 16
			strokewidth: 2
		}
		artistic2: {
			qtres: 0.01
			colorsampling: 0
			colorquantcycles: 1
			numberofcolors: 4
			strokewidth: 0
		}
		artistic3: {qtres: 10, ltres: 10, numberofcolors: 8}
		artistic4: {
			qtres: 10
			ltres: 10
			numberofcolors: 64
			blurradius: 5
			blurdelta: 256
			strokewidth: 2
		}
		posterized3: {
			ltres: 1
			qtres: 1
			pathomit: 20
			rightangleenhance: true
			colorsampling: 0
			numberofcolors: 3
			mincolorratio: 0
			colorquantcycles: 3
			blurradius: 3
			blurdelta: 20
			strokewidth: 0
			roundcoords: 1
			pal: {
				{r: 0, g: 0, b: 100, a: 255},
				{r: 255, g: 255, b: 255, a: 255}
			}
		}
	}

	gks: {
		{0.27901, 0.44198, 0.27901}
		{0.135336, 0.228569, 0.272192, 0.228569, 0.135336}
		{0.086776, 0.136394, 0.178908, 0.195843, 0.178908, 0.136394, 0.086776}
		{0.063327, 0.093095, 0.122589, 0.144599, 0.152781, 0.144599, 0.122589, 0.093095, 0.063327}
		{0.049692, 0.069304, 0.089767, 0.107988, 0.120651, 0.125194, 0.120651, 0.107988, 0.089767, 0.069304, 0.049692}
	}

	-- Lookup tables for pathscan
	-- pathscan_combined_lookup[ arr[py][px] ][ dir ] = [nextarrpypx, nextdir, deltapx, deltapy];
	pathscan_combined_lookup: {
		{{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
		{{0, 1, 0, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}}
		{{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1}, {0, 0, 1, 0}}
		{{0, 0, 1, 0}, {-1, -1, -1, -1}, {0, 2, -1, 0}, {-1, -1, -1, -1}}
		{{-1, -1, -1, -1}, {0, 0, 1, 0}, {0, 3, 0, 1}, {-1, -1, -1, -1}}
		{{13, 3, 0, 1}, {13, 2, -1, 0}, {7, 1, 0, -1}, {7, 0, 1, 0}}
		{{-1, -1, -1, -1}, {0, 1, 0, -1}, {-1, -1, -1, -1}, {0, 3, 0, 1}}
		{{0, 3, 0, 1}, {0, 2, -1, 0}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
		{{0, 3, 0, 1}, {0, 2, -1, 0}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
		{{-1, -1, -1, -1}, {0, 1, 0, -1}, {-1, -1, -1, -1}, {0, 3, 0, 1}}
		{{11, 1, 0, -1}, {14, 0, 1, 0}, {14, 3, 0, 1}, {11, 2, -1, 0}}
		{{-1, -1, -1, -1}, {0, 0, 1, 0}, {0, 3, 0, 1}, {-1, -1, -1, -1}}
		{{0, 0, 1, 0}, {-1, -1, -1, -1}, {0, 2, -1, 0}, {-1, -1, -1, -1}}
		{{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1}, {0, 0, 1, 0}}
		{{0, 1, 0, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}}
		{{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
	}

	tableConcat: (tb, ...) ->
		items, result = {...}, {}
		for i = 1, #tb
			insert result, tb[i]
		for i = 1, #items
			item = items[i]
			if type(item) == "table"
				for j = 1, #item
					insert result, item[j]
			else
				insert result, item
		return result

	checkoptions: (options = {}) ->
		if type(options) == "string"
			options = options\lower!
			if Tracer.optionpresets["default"]
				options = Tracer.optionpresets[options]
			else
				options = {}
		ok = {}
		for k in pairs Tracer.optionpresets["default"]
			insert ok, k
		for k = 1, #ok
			unless rawget options, ok[k]
				options[ok[k]] = Tracer.optionpresets["default"][ok[k]]
		return options

	-- Generating a palette with numberofcolors
	generatepalette: (numberofcolors) ->
		palette = {}
		if numberofcolors < 8
			graystep = math.floor 255 / (numberofcolors - 1)
			for i = 0, numberofcolors - 1
				insert palette, {r: i * graystep, g: i * graystep, b: i * graystep, a: 255}
		else
			colorqnum = math.floor numberofcolors ^ (1 / 3)
			colorstep = math.floor 255 / (colorqnum - 1)
			rndnum = numberofcolors - colorqnum ^ 3
			for rcnt = 0, colorqnum - 1
				for gcnt = 0, colorqnum - 1
					for bcnt = 0, colorqnum - 1
						insert palette, {r: rcnt * colorstep, g: gcnt * colorstep, b: bcnt * colorstep, a: 255}
			for rcnt = 0, rndnum - 1
				insert palette, {
					r: math.floor math.random! * 255
					g: math.floor math.random! * 255
					b: math.floor math.random! * 255
					a: math.floor math.random! * 255
				}
		return palette

	-- Sampling a palette from imagedata
	samplepalette: (numberofcolors, imgd) ->
		palette, len = {}, imgd.width * imgd.height
		for i = 0, numberofcolors - 1
			idx = math.floor math.random! * (len + 1)
			pix = imgd.data[idx]
			insert palette, {r: pix.r, g: pix.g, b: pix.b, a: pix.a}
		return palette

	samplepalette2: (numberofcolors, imgd) ->
		palette = {}
		ni = math.ceil math.sqrt numberofcolors
		nj = math.ceil numberofcolors / ni
		vx = imgd.width / (ni + 1)
		vy = imgd.height / (nj + 1)
		for j = 0, nj - 1
			for i = 0, ni - 1
				if #palette == numberofcolors
					break
				else
					idx = math.floor (j + 1) * vy * imgd.width + (i + 1) * vx
					with imgd.data[idx]
						insert palette, {r: .r, g: .g, b: .b, a: .a}
		return palette

	blur: (imgd, radius, delta) ->
		imgd2 = {width: imgd.width, height: imgd.height, data: ffi.new "color_RGBA[?]", imgd.width * imgd.height}
		radius = math.floor radius
		if radius < 1
			return imgd
		if radius > 5
			radius = 5
		delta = math.abs delta
		if delta > 1024
			delta = 1024
		thisgk = Tracer.gks[radius]
		for j = 0, imgd.height - 1
			for i = 0, imgd.width - 1
				racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
				for k = -radius, radius
					if (i + k > 0) and (i + k < imgd.width)
						idx = j * imgd.width + i + k
						pix = imgd.data[idx]
						val = thisgk[k + radius + 1]
						racc += pix.r * val
						gacc += pix.g * val
						bacc += pix.b * val
						aacc += pix.a * val
						wacc += val
				idx = j * imgd.width + i
				imgd2.data[idx].r = math.floor racc / wacc
				imgd2.data[idx].g = math.floor gacc / wacc
				imgd2.data[idx].b = math.floor bacc / wacc
				imgd2.data[idx].a = math.floor aacc / wacc
		himgd = ffi.new "color_RGBA[?]", imgd.width * imgd.height
		for j = 0, imgd.height - 1
			for i = 0, imgd.width - 1
				idx = j * imgd.width + i
				pix = imgd.data[idx]
				pix2 = imgd2.data[idx]
				d = math.abs(pix2.r - pix.r) + math.abs(pix2.g - pix.g) + math.abs(pix2.b - pix.b) + math.abs(pix2.a - pix.a)
				if d > delta
					with pix
						imgd2.data[idx].r = .r
						imgd2.data[idx].g = .g
						imgd2.data[idx].b = .b
						imgd2.data[idx].a = .a
		return imgd2

	-- Using a form of k-means clustering repeatead options.colorquantcycles times. http://en.wikipedia.org/wiki/Color_quantization
	colorquantization: (imgd, options) ->
		arr = {}
		paletteacc = {}
		pixelnum = imgd.width * imgd.height
		for j = 0, imgd.height + 1
			arr[j] = {}
			for i = 0, imgd.width + 1
				arr[j][i] = -1
		local palette
		if options.pal
			palette = options.pal
		elseif options.colorsampling == 0
			palette = Tracer.generatepalette options.numberofcolors
		elseif options.colorsampling == 1
			palette = Tracer.samplepalette options.numberofcolors, imgd
		else
			palette = Tracer.samplepalette2 options.numberofcolors, imgd
		if options.blurradius > 0
			imgd = Tracer.blur imgd, options.blurradius, options.blurdelta
		for cnt = 0, options.colorquantcycles - 1
			if cnt > 0
				for k = 1, #palette
					pix = paletteacc[k]
					if pix.n > 0
						palette[k] = {
							r: math.floor pix.r / pix.n
							g: math.floor pix.g / pix.n
							b: math.floor pix.b / pix.n
							a: math.floor pix.a / pix.n
						}
					if pix.n / pixelnum < options.mincolorratio and cnt < options.colorquantcycles - 1
						palette[k] = {
							r: math.floor math.random! * 255
							g: math.floor math.random! * 255
							b: math.floor math.random! * 255
							a: math.floor math.random! * 255
						}
			for i = 1, #palette
				paletteacc[i] = {r: 0, g: 0, b: 0, a: 0, n: 0}
			for j = 0, imgd.height - 1
				for i = 0, imgd.width - 1
					idx = j * imgd.width + i
					ci = 0
					cdl = 1024
					pix = imgd.data[idx]
					for k = 1, #palette
						with palette[k]
							cd = math.abs(.r - pix.r) + math.abs(.g - pix.g) + math.abs(.b - pix.b) + math.abs(.a - pix.a)
							if cd < cdl
								cdl = cd
								ci = k - 1
					with pix
						paletteacc[ci+1].r += .r
						paletteacc[ci+1].g += .g
						paletteacc[ci+1].b += .b
						paletteacc[ci+1].a += .a
						paletteacc[ci+1].n += 1
					arr[j + 1][i + 1] = ci

		return {array: arr, :palette}

	-- Edge node types ( ▓: this layer or 1; ░: not this layer or 0 )
	-- 12  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓
	-- 48  ░░  ░░  ░░  ░░  ░▓  ░▓  ░▓  ░▓  ▓░  ▓░  ▓░  ▓░  ▓▓  ▓▓  ▓▓  ▓▓
	--     0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
	layeringstep: (ii, cnum) ->
		layer = {}
		ah = #ii.array + 1
		aw = #ii.array[0] + 1
		for j = 0, ah - 1
			layer[j] = {}
			for i = 0, aw - 1
				layer[j][i] = 0
		for j = 1, ah - 1
			for i = 1, aw - 1
				value1 = ii.array[j-1][i-1] == cnum and 1 or 0
				value2 = ii.array[j-1][i] == cnum and 2 or 0
				value3 = ii.array[j][i-1] == cnum and 8 or 0
				value4 = ii.array[j][i] == cnum and 4 or 0
				layer[j][i] = value1 + value2 + value3 + value4
		return layer

	-- Edge node types ( ▓: this layer or 1; ░: not this layer or 0 )
	-- 12  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓
	-- 48  ░░  ░░  ░░  ░░  ░▓  ░▓  ░▓  ░▓  ▓░  ▓░  ▓░  ▓░  ▓▓  ▓▓  ▓▓  ▓▓
	--     0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
	layering: (ii) ->
		layers = {}
		val = 0
		ah = #ii.array + 1
		aw = #ii.array[0] + 1
		for k = 0, #ii.palette - 1
			layers[k] = {}
			for j = 0, ah - 1
				layers[k][j] = {}
				for i = 0, aw - 1
					layers[k][j][i] = 0
		for j = 1, ah - 2
			for i = 1, aw - 2
				val = ii.array[j][i]
				n1 = ii.array[j - 1][i - 1] == val and 1 or 0
				n2 = ii.array[j - 1][i] == val and 1 or 0
				n3 = ii.array[j - 1][i + 1] == val and 1 or 0
				n4 = ii.array[j][i - 1] == val and 1 or 0
				n5 = ii.array[j][i + 1] == val and 1 or 0
				n6 = ii.array[j + 1][i - 1] == val and 1 or 0
				n7 = ii.array[j + 1][i] == val and 1 or 0
				n8 = ii.array[j + 1][i + 1] == val and 1 or 0
				layers[val][j + 1][i + 1] = 1 + n5 * 2 + n8 * 4 + n7 * 8
				unless n4
					layers[val][j + 1][i] = 0 + 2 + n7 * 4 + n6 * 8
				unless n2
					layers[val][j][i + 1] = 0 + n3 * 2 + n5 * 4 + 8
				unless n1
					layers[val][j][i] = 0 + n2 * 2 + 4 + n4 * 8
		return layers

	boundingboxincludes: (parentbbox, childbbox) ->
		return parentbbox[1] < childbbox[1] and parentbbox[2] < childbbox[2] and parentbbox[3] > childbbox[3] and parentbbox[4] > childbbox[4]

	batchpathscan: (layers, pathomit) ->
		bpaths = {}
		for k in pairs layers
			unless rawget layers, k
				continue
			bpaths[k] = Tracer.pathscan layers[k], pathomit
		return bpaths

	-- https://stackoverflow.com/a/28130452/15411556
	pointInsidePolygon: (p, points, ep = 0.1) ->
		n = #points
		j = n
		r = false
		for i = 1, n
			a = points[i]
			b = points[j]
			if math.abs(a.y - b.y) <= ep and math.abs(b.y - p.y) <= ep and (a.x >= p.x) != (b.x >= p.x)
				return true
			if (a.y > p.y) != (b.y > p.y)
				c = (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x
				if math.abs(p.x - c) <= ep
					return true
				if p.x < c
					r = not r
			j = i
		return r

	pathscan: (arr, pathomit) ->
		paths = {}
		pacnt, pcnt = 1, 1
		px, py = 0, 0
		w = #arr[0] + 1
		h = #arr + 1
		dir = 0
		pathfinished = true
		holepath = false
		for j = 0, h - 1
			for i = 0, w - 1
				if (arr[j][i] == 4) or (arr[j][i] == 11)
					px = i
					py = j
					paths[pacnt] = {}
					paths[pacnt].points = {}
					paths[pacnt].boundingbox = {px, py, px, py}
					paths[pacnt].holechildren = {}
					pathfinished = false
					pcnt = 1
					holepath = arr[j][i] == 11
					dir = 1
					while not pathfinished
						paths[pacnt].points[pcnt] = {}
						paths[pacnt].points[pcnt].x = px - 1
						paths[pacnt].points[pcnt].y = py - 1
						paths[pacnt].points[pcnt].t = arr[py][px]
						if px - 1 < paths[pacnt].boundingbox[1]
							paths[pacnt].boundingbox[1] = px - 1
						if px - 1 > paths[pacnt].boundingbox[3]
							paths[pacnt].boundingbox[3] = px - 1
						if py - 1 < paths[pacnt].boundingbox[2]
							paths[pacnt].boundingbox[2] = py - 1
						if py - 1 > paths[pacnt].boundingbox[4]
							paths[pacnt].boundingbox[4] = py - 1
						lookuprow = Tracer.pathscan_combined_lookup[arr[py][px]+1][dir+1]
						arr[py][px] = lookuprow[1]
						dir = lookuprow[2]
						px += lookuprow[3]
						py += lookuprow[4]
						if (px - 1 == paths[pacnt].points[1].x) and (py - 1 == paths[pacnt].points[1].y)
							pathfinished = true

							if #paths[pacnt].points < pathomit
								remove paths
							else
								paths[pacnt].isholepath = holepath and true or false
								if holepath
									parentidx = 1
									parentbbox = {-1, -1, w + 1, h + 1}
									for parentcnt = 1, pacnt
										cond1 = not paths[parentcnt].isholepath
										cond2 = Tracer.boundingboxincludes paths[parentcnt].boundingbox, paths[pacnt].boundingbox
										cond3 = Tracer.boundingboxincludes parentbbox, paths[parentcnt].boundingbox
										cond4 = Tracer.pointInsidePolygon paths[pacnt].points[1], paths[parentcnt].points
										if cond1 and cond2 and cond3 and cond4
											parentidx = parentcnt
											parentbbox = paths[parentcnt].boundingbox
									insert paths[parentidx].holechildren, pacnt
								pacnt += 1
						pcnt += 1
		return paths

	testrightangle: (path, idx1, idx2, idx3, idx4, idx5) ->
		cond1 = path.points[idx3].x == path.points[idx1].x
		cond2 = path.points[idx3].x == path.points[idx2].x
		cond3 = path.points[idx3].y == path.points[idx4].y
		cond4 = path.points[idx3].y == path.points[idx5].y
		cond5 = path.points[idx3].y == path.points[idx1].y
		cond6 = path.points[idx3].y == path.points[idx2].y
		cond7 = path.points[idx3].x == path.points[idx4].x
		cond8 = path.points[idx3].x == path.points[idx5].x
		return (cond1 and cond2 and cond3 and cond4) or (cond5 and cond6 and cond7 and cond8)

	getdirection: (x1, y1, x2, y2) ->
		val = 8
		if x1 < x2
			if y1 < y2
				val = 1
			elseif y1 > y2
				val = 7
			else
				val = 0
		elseif x1 > x2
			if y1 < y2
				val = 3
			elseif y1 > y2
				val = 5
			else
				val = 4
		else
			if y1 < y2
				val = 2
			elseif y1 > y2
				val = 6
			else
				val = 8
		return val

	-- interpollating between path points for nodes with 8 directions ( East, SouthEast, S, SW, W, NW, N, NE )
	internodes: (paths, options) ->
		ins = {}
		for pacnt = 1, #paths
			ins[pacnt] = {}
			ins[pacnt].points = {}
			ins[pacnt].boundingbox = paths[pacnt].boundingbox
			ins[pacnt].holechildren = paths[pacnt].holechildren
			ins[pacnt].isholepath = paths[pacnt].isholepath
			palen = #paths[pacnt].points
			for pcnt = 1, palen
				nextidx = pcnt % palen + 1
				nextidx2 = (pcnt + 1) % palen + 1
				previdx = (pcnt + palen - 2) % palen + 1
				previdx2 = (pcnt + palen - 3) % palen + 1
				if options.rightangleenhance and Tracer.testrightangle paths[pacnt], previdx2, previdx, pcnt, nextidx, nextidx2
					if #ins[pacnt].points > 0
						ins[pacnt].points[#ins[pacnt].points].linesegment = Tracer.getdirection ins[pacnt].points[#ins[pacnt].points].x, ins[pacnt].points[#ins[pacnt].points].y, paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y
					insert ins[pacnt].points, {
						x: paths[pacnt].points[pcnt].x
						y: paths[pacnt].points[pcnt].y
						linesegment: Tracer.getdirection paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y, (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2
					}
				insert ins[pacnt].points, {
					x: (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2
					y: (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2
					linesegment: Tracer.getdirection (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2, (paths[pacnt].points[nextidx].x + paths[pacnt].points[nextidx2].x) / 2, (paths[pacnt].points[nextidx].y + paths[pacnt].points[nextidx2].y) / 2
				}
		return ins

	batchinternodes: (bpaths, options) ->
		binternodes = {}
		for k in pairs bpaths
			unless rawget bpaths, k
				continue
			binternodes[k] = Tracer.internodes bpaths[k], options
		return binternodes

	-- 5.2. - 5.6. recursively fitting a straight or quadratic line segment on this sequence of path nodes,
	-- called from tracepath()
	fitseq: (path, ltres, qtres, seqstart, seqend) ->
		if seqend > #path.points or seqend < 0
			return {}
		errorpoint = seqstart
		errorval = 0
		curvepass = true
		tl = seqend - seqstart
		if tl < 0
			tl = tl + #path.points
		vx = (path.points[seqend+1].x - path.points[seqstart+1].x) / tl
		vy = (path.points[seqend+1].y - path.points[seqstart+1].y) / tl
		pcnt = (seqstart + 1) % #path.points
		while pcnt != seqend
			pl = pcnt - seqstart
			if pl < 0
				pl = pl + #path.points
			px = path.points[seqstart+1].x + vx * pl
			py = path.points[seqstart+1].y + vy * pl
			dist2 = (path.points[pcnt+1].x - px) * (path.points[pcnt+1].x - px) + (path.points[pcnt+1].y - py) * (path.points[pcnt+1].y - py)
			if dist2 > ltres
				curvepass = false
			if dist2 > errorval
				errorpoint = pcnt
				errorval = dist2
			pcnt = (pcnt + 1) % #path.points
		if curvepass
			return {{type: "l", x1: path.points[seqstart+1].x, y1: path.points[seqstart+1].y, x2: path.points[seqend+1].x, y2: path.points[seqend+1].y}}
		fitpoint = errorpoint
		curvepass = true
		errorval = 0
		t = (fitpoint - seqstart) / tl
		t1 = (1 - t) * (1 - t)
		t2 = 2 * (1 - t) * t
		t3 = t * t
		cpx = (t1 * path.points[seqstart+1].x + t3 * path.points[seqend+1].x - path.points[fitpoint+1].x) / -t2
		cpy = (t1 * path.points[seqstart+1].y + t3 * path.points[seqend+1].y - path.points[fitpoint+1].y) / -t2
		pcnt = seqstart + 1
		while pcnt != seqend
			t = (pcnt - seqstart) / tl
			t1 = (1 - t) * (1 - t)
			t2 = 2 * (1 - t) * t
			t3 = t * t
			px = t1 * path.points[seqstart+1].x + t2 * cpx + t3 * path.points[seqend+1].x
			py = t1 * path.points[seqstart+1].y + t2 * cpy + t3 * path.points[seqend+1].y
			dist2 = (path.points[pcnt+1].x - px) * (path.points[pcnt+1].x - px) + (path.points[pcnt+1].y - py) * (path.points[pcnt+1].y - py)
			if dist2 > qtres
				curvepass = false
			if dist2 > errorval
				errorpoint = pcnt
				errorval = dist2
			pcnt = (pcnt + 1) % #path.points
		if curvepass
			x1, y1 = path.points[seqstart+1].x, path.points[seqstart+1].y
			x2, y2 = cpx, cpy
			x3, y3 = path.points[seqend+1].x, path.points[seqend+1].y
			return {{type: "b", x1: x1, y1: y1, x2: (x1 + 2 * x2) / 3, y2: (y1 + 2 * y2) / 3, x3: (x3 + 2 * x2) / 3, y3: (y3 + 2 * y2) / 3, x4: x3, y4: y3}}
		splitpoint = fitpoint
		return Tracer.tableConcat Tracer.fitseq(path, ltres, qtres, seqstart, splitpoint), Tracer.fitseq(path, ltres, qtres, splitpoint, seqend)

	-- 5. tracepath() : recursively trying to fit straight and quadratic spline segments on the 8 direction internode path
	-- 5.1. Find sequences of points with only 2 segment types
	-- 5.2. Fit a straight line on the sequence
	-- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
	-- 5.4. Fit a quadratic spline through errorpoint (project this to get controlpoint), then measure errors on every point in the sequence
	-- 5.5. If the spline fails (distance error > qtres), find the point with the biggest error, set splitpoint = fitting point
	-- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
	tracepath: (path, ltres, qtres) ->
		pcnt = 0
		smp = {}
		smp.segments = {}
		smp.boundingbox = path.boundingbox
		smp.holechildren = path.holechildren
		smp.isholepath = path.isholepath
		while pcnt < #path.points
			segtype1 = path.points[pcnt+1].linesegment
			segtype2 = -1
			seqend = pcnt + 1
			while (path.points[seqend+1].linesegment == segtype1 or path.points[seqend+1].linesegment == segtype2 or segtype2 == -1) and seqend < #path.points - 1
				if path.points[seqend+1].linesegment != segtype1 and segtype2 == -1
					segtype2 = path.points[seqend+1].linesegment
				seqend = seqend + 1
			if seqend == #path.points - 1
				seqend = 0
			smp.segments = Tracer.tableConcat smp.segments, Tracer.fitseq path, ltres, qtres, pcnt, seqend
			if seqend > 0
				pcnt = seqend
			else
				pcnt = #path.points
		return smp

	-- Batch tracing paths
	batchtracepaths: (internodepaths, ltres, qtres) ->
		btracedpaths = {}
		for k in pairs internodepaths
			unless rawget internodepaths, k
				continue
			insert btracedpaths, Tracer.tracepath internodepaths[k], ltres, qtres
		return btracedpaths

	-- Batch tracing layers
	batchtracelayers: (binternodes, ltres, qtres) ->
		btbis = {}
		for k in pairs binternodes
			unless rawget binternodes, k
				continue
			btbis[k] = Tracer.batchtracepaths binternodes[k], ltres, qtres
		return btbis

	-- Tracing imagedata, then returning tracedata (layers with paths, palette, image size)
	imagedataToTracedata: (imgd, options) ->
		local tracedata
		options = Tracer.checkoptions options
		ii = Tracer.colorquantization imgd, options
		if options.layering == 0
			tracedata = {
				layers: {}
				palette: ii.palette
				width: #ii.array[0] - 1
				height: #ii.array - 1
			}
			for colornum = 1, #ii.palette
				value1 = Tracer.layeringstep ii, colornum - 1
				value2 = Tracer.pathscan value1, options.pathomit
				value3 = Tracer.internodes value2, options
				insert tracedata.layers, Tracer.batchtracepaths value3, options.ltres, options.qtres
		else
			ls = Tracer.layering ii
			bps = Tracer.batchpathscan ls, options.pathomit
			bis = Tracer.batchinternodes bps, options
			tracedata = {
				layers: Tracer.batchtracelayers bis, options.ltres, options.qtres
				palette: ii.palette
				width: imgd.width
				height: imgd.height
			}
		return tracedata

	round: (a, dec = 3) ->
		t = 10 ^ math.floor dec
		a = math.floor a * t + 0.5
		b = math.floor a + 0.5
		return dec >= 1 and a / t or b

	assColor: (c) ->
		local color, alpha
		with c
			color = ("&H%02X%02X%02X&")\format .b, .g, .r
			alpha = ("&H%02X&")\format 255 - .a
		return color, alpha

	assDraw: (tracedata, lnum, pathnum, options) ->
		{:roundcoords, :scale} = options
		round = roundcoords < 0 and 0 or roundcoords
		layer = tracedata.layers[lnum]
		smp = layer[pathnum]
		if #smp.segments < 3
			return ""
		shape = ("m %s %s ")\format Tracer.round(smp.segments[1].x1 * scale, round), Tracer.round(smp.segments[1].y1 * scale, round)
		local currType
		for pcnt = 1, #smp.segments
			seg = smp.segments[pcnt]
			if currType != seg.type
				currType = seg.type
				shape ..= ("%s %s %s ")\format seg.type, Tracer.round(seg.x2 * scale, round), Tracer.round(seg.y2 * scale, round)
			else
				shape ..= ("%s %s ")\format Tracer.round(seg.x2 * scale, round), Tracer.round(seg.y2 * scale, round)
			if rawget seg, "x4"
				shape ..= ("%s %s %s %s ")\format Tracer.round(seg.x3 * scale, round), Tracer.round(seg.y3 * scale, round), Tracer.round(seg.x4 * scale, round), Tracer.round(seg.y4 * scale, round)
		for hcnt = 1, #smp.holechildren
			hsmp = layer[smp.holechildren[hcnt]]
			seg = hsmp.segments[#hsmp.segments]
			if rawget seg, "x4"
				shape ..= ("m %s %s l %s %s ")\format Tracer.round(seg.x3 * scale), Tracer.round(seg.y3 * scale), Tracer.round(seg.x4 * scale), Tracer.round(seg.y4 * scale)
			else
				shape ..= ("m %s %s ")\format Tracer.round(seg.x2 * scale), Tracer.round(seg.y2 * scale)
			local currType
			for pcnt = #hsmp.segments, 1, -1
				seg = hsmp.segments[pcnt]
				if currType != seg.type
					currType = seg.type
					shape ..= currType .. " "
				if rawget seg, "x4"
					shape ..= ("%s %s %s %s ")\format Tracer.round(seg.x2 * scale), Tracer.round(seg.y2 * scale), Tracer.round(seg.x3 * scale), Tracer.round(seg.y3 * scale)
				shape ..= ("%s %s ")\format Tracer.round(seg.x1 * scale), Tracer.round(seg.y1 * scale)
		palette = tracedata.palette[lnum]
		if palette.a != 0
			return shape, Tracer.assColor palette

	-- Converting tracedata to an assDraw
	getAssLines: (tracedata, options) ->
		preset = "{\\an7\\pos(0,0)\\c%s\\3c%s\\alpha%s\\fscx100\\fscy100\\bord%d\\shad0\\frz0\\p1}%s"
		values, options = {}, Tracer.checkoptions options
		for lcnt = 1, #tracedata.layers
			for pcnt = 1, #tracedata.layers[lcnt]
				if not tracedata.layers[lcnt][pcnt].isholepath
					shape, color, alpha = Tracer.assDraw tracedata, lcnt, pcnt, options
					if color
						index = color .. alpha
						values[index] or= {}
						insert values[index], {color, alpha, shape}
		shapes = {}
		for color, val in pairs values
			newShape = ""
			{currColor, currAlpha} = val[1]
			for v in *val
				newShape ..= v[3]
			insert shapes, (preset)\format currColor, currColor, currAlpha, options.strokewidth, newShape
		return shapes

{:Tracer}