module_version = "1.0.2"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl
if haveDepCtrl
	depctrl = DependencyControl {
		name: "ILL"
		version: module_version
		description: "A library for loading images in various formats"
		author: "Zeref"
		moduleName: "ILL.IMG"
		url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts"
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
		{
			{"ffi"}
			{"requireffi.requireffi", version: "0.1.2"}
		}
	}

import LIBBMP  from require "ILL.IMG.bitmap.bitmap"
import LIBJPG  from require "ILL.IMG.turbojpeg.turbojpeg"
import LIBGIF  from require "ILL.IMG.giflib.giflib"
import LIBPNG  from require "ILL.IMG.lodepng.lodepng"
import Tracer  from require "ILL.IMG.Tracer"
import Potrace from require "ILL.IMG.Potrace"

class IMG

	new: (filename) =>
		if filename and type(filename) == "string"
			@extension = filename\match "^.+%.(.+)$"
			@infos = switch @extension
				when "png"                               then LIBPNG(filename)\decode!
				when "jpeg", "jpe", "jpg", "jfif", "jfi" then LIBJPG(filename)\decode!
				when "bmp", "dib"                        then LIBBMP(filename)\decode!
				when "gif"                               then LIBGIF(filename)\decode!
				else error "Invalid image format", 2
		else
			error "Expected filename", 2

	setInfos: (frame = 1) =>
		infos = @extension == "gif" and @infos.frames[frame] or @infos
		if @extension == "gif"
			{delayMs: @delayMs, x: @x, y: @y} = infos
		@width = infos.width
		@height = infos.height
		@data = infos\getData!

	toAss: (reduce, frame) =>
		@setInfos frame
		preset = "{\\an7\\pos(%d,%d)\\fscx100\\fscy100\\bord0\\shad0\\frz0%s\\p1}%s"

		-- converts the color data to the .ass format
		data2ass = (data) ->
			return unless data
			{:b, :g, :r, :a} = data
			color = ("\\cH%02X%02X%02X")\format b, g, r
			alpha = ("\\alphaH%02X")\format 255 - a
			return color, alpha

		-- gets the colors in .ass format through the pixel coordinate
		pixel2ass = (x, y) ->
			i = y * @width + x
			currColor, currAlpha = data2ass @data[i]
			nextColor, nextAlpha = data2ass @data[i + 1]
			return currColor, nextColor, currAlpha, nextAlpha

		-- converts all pixels of the image to the .ass format
		img2pixels = (pixels = {}) ->
			for y = 0, @height - 1
				for x = 0, @width - 1
					color, alpha = data2ass @data[y * @width + x]
					if alpha != "\\alphaHFF"
						table.insert pixels, (preset)\format x, y, color .. alpha, "m 0 0 l 1 0 1 1 0 1"
			return pixels

		-- simplifies the number of pixels in each row of the image
		img2reduced_pixels = (oneLine, pixels = {}) ->
			for y = 0, @height - 1
				x, tempRow, tempAlpha = 0, "", nil
				while x < @width
					-- gets the color information of the current coordinate
					currColor, nextColor, currAlpha = pixel2ass x, y
					-- saves the current values of x, color and alpha
					start, color, alpha = x, currColor, currAlpha
					-- while the current color is equal to the next color
					while nextColor and (currColor == nextColor)
						x += 1
						if x >= @width - 1
							break
						-- updates the color information of the current coordinate
						currColor, nextColor, currAlpha = pixel2ass x, y
					-- gets the repeat color offset
					offset = x - start + 1
					-- if the offset value is equal to the image width
					-- and all pixels on this row are invisible, skip
					unless (offset == @width and alpha == "\\alphaHFF")
						tempRow ..= ("{%s}m 0 0 l %d 0 %d 1 0 1")\format color .. ((tempAlpha and tempAlpha == alpha) and "" or alpha), offset, offset
						tempAlpha = alpha
					x += 1
				-- add the row if it exists
				unless tempRow == ""
					table.insert pixels, (preset)\format 0, y, "", tempRow

			if oneLine
				line = ""
				for pixel in *pixels
					line ..= pixel\gsub("%b{}", "", 1) .. "{\\p0}\\N{\\p1}"
				line = (preset)\format(0, 0, "", line)\gsub "{\\p0}\\N{\\p1}$", ""
				return {line}

			return pixels

		return reduce and (reduce == "oneLine" and img2reduced_pixels(true) or img2reduced_pixels!) or img2pixels!

modules = {
	:IMG
	:LIBBMP
	:LIBJPG
	:LIBGIF
	:LIBPNG
	:Tracer
	:Potrace
	version: module_version
}

if haveDepCtrl
	depctrl\register modules
else
	modules