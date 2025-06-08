ffi = require "ffi"
require "zimg.main.buffer.buffer"

bmp_header = {
    offset: 0
    pixel_offset: 10
    width: 18
    height: 22
    bpp: 28
    compression: 30
}

-- https://github.com/max1220/lua-bitmap
class LIBBMP

    new: (@filename = filename) =>
        file = io.open @filename, "rb"

        unless file
            error "Can't open input file for reading: #{@filename}"

        raw = file\read "*a"
        assert raw and raw != "", "Can't read input file: #{@filename}"

        file\close!

        @raw = {}
        for i = 1, #raw
            @raw[i - 1] = raw\sub(i, i)\byte!

    -- reading 8/16/32-bit little-endian integer values from a string
    -- read uint8
    read: (offset) =>
        offset = tonumber offset
        assert offset
        value = @raw[math.floor(offset)]
        assert value
        return value

    -- read uint16
    read_word: (offset) => @read(offset + 1) * 0x100 + @read offset

    -- read uint32
    read_dword: (offset) => @read(offset + 3) * 0x1000000 + @read(offset + 2) * 0x10000 + @read(offset + 1) * 0x100 + @read offset

    -- read int32
    read_long: (offset) =>
        value = @read_dword offset
        if value >= 0x8000000
            value = -(value - 0x80000000)
        return value

    decode: =>
        -- check the bitmap header
        unless @read_word(bmp_header.offset) == 0x4D42
            error "Bitmap magic header not found"

        compression = @read_dword bmp_header.compression
        if compression != 0
            error "Only uncompressed bitmaps supported. Is: #{compression}"

        -- get bits per pixel from the bitmap header
        -- this library only supports 24bpp and 32bpp pixel formats!
        @bit_depth = @read_word bmp_header.bpp
        unless @bit_depth == 24 or @bit_depth == 32
            error "Only 24bpp/32bpp bitmaps supported. Is: #{@bit_depth}"

        -- get other required info from the bitmap header
        @pxOffset = @read_dword bmp_header.pixel_offset
        @width = @read_long bmp_header.width
        @height = @read_long bmp_header.height

        -- if height is < 0, the image data is in topdown format
        @topdown = true
        if @height < 0
            @topdown, @height = false, -@height

        @getPixel = (x, y) =>
            if (x < 0) or (x >= @width) or (y < 0) or (y >= @height)
                error "Out of bounds"

            -- calculate byte offset in data
            bpp = @bit_depth / 8
            lineW = math.ceil(@width / 4) * 4
            index = @pxOffset + y * lineW * bpp + x * bpp
            if @topdown
                index = @pxOffset + (@height - y - 1) * bpp * lineW + x * bpp

            b = @read index
            g = @read index + 1
            r = @read index + 2
            a = bpp < 4 and 255 or @read index + 3
            return r, g, b, a

        @getData = =>
            @data = ffi.new "color_RGBA[?]", @width * @height

            for y = 0, @height - 1
                for x = 0, @width - 1
                    r, g, b, a = @getPixel x, y
                    with @data[y * @width + x]
                        .r = r
                        .g = g
                        .b = b
                        .a = a

            return @data

        return @

{:LIBBMP}