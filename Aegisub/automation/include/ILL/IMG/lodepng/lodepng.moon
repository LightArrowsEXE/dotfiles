ffi = require "ffi"
requireffi = require "requireffi.requireffi"
bff = require "ILL.IMG.buffer.buffer"

has_loaded, PNG = pcall requireffi, "ILL.IMG.lodepng.lodepng.lodepng"

ffi.cdef [[
	typedef enum {
		LCT_GREY = 0,
		LCT_RGB = 2,
		LCT_PALETTE = 3,
		LCT_GREY_ALPHA = 4,
		LCT_RGBA = 6,
	} LodePNGColorType;
	const char *LODEPNG_VERSION_STRING;
	const char *lodepng_error_text(unsigned int);
	unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
]]

-- https://github.com/koreader/koreader-base/tree/master/ffi
class LIBPNG

	new: (@filename = filename) =>

	setArguments: =>
		@rawData = ffi.new "unsigned char*[1]"
		@width = ffi.new "int[1]"
		@height = ffi.new "int[1]"

	decode: =>
		@setArguments!

		err = PNG.lodepng_decode32_file @rawData, @width, @height, @filename
		assert err == 0, ffi.string PNG.lodepng_error_text err

		buffer = bff.BUFFER @width[0], @height[0], 5, @rawData[0]
		buffer\set_allocated 1

		@rawData = buffer
		@width = buffer\get_width!
		@height = buffer\get_height!
		@bit_depth = buffer\get_bpp!

		@getPixel = (x, y) => buffer\get_pixel x, y

		@getData = =>
			@data = ffi.new "color_RGBA[?]", @width * @height

			for y = 0, @height - 1
				for x = 0, @width - 1
					i = y * @width + x
					with @getPixel(x, y)\get_color_32!
						@data[i].r = .r
						@data[i].g = .g
						@data[i].b = .b
						@data[i].a = .alpha

			return @data

		return @

{:LIBPNG}