ffi = require "ffi"
requireffi = require "requireffi.requireffi"
bff = require "zimg.main.buffer.buffer"

has_loaded, JPG = pcall requireffi, "zimg.main.turbojpeg.turbojpeg.turbojpeg"

ffi.cdef [[
    typedef void *tjhandle;
    typedef enum {
        TJPF_RGB = 0,
        TJPF_BGR = 1,
        TJPF_RGBX = 2,
        TJPF_BGRX = 3,
        TJPF_XBGR = 4,
        TJPF_XRGB = 5,
        TJPF_GRAY = 6,
        TJPF_RGBA = 7,
        TJPF_BGRA = 8,
        TJPF_ABGR = 9,
        TJPF_ARGB = 10,
        TJPF_CMYK = 11,
        TJPF_UNKNOWN = -1,
    } TJPF;
    typedef enum {
        TJSAMP_444 = 0,
        TJSAMP_422,
        TJSAMP_420,
        TJSAMP_GRAY,
        TJSAMP_440,
        TJSAMP_411
    } TJPF;
    int tjDestroy(tjhandle handle);
    tjhandle tjInitDecompress(void);
    int tjDecompressHeader3(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, int *width, int *height, int *jpegSubsamp, int *jpegColorspace);
    int tjDecompress2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags);
]]

-- https://github.com/koreader/koreader-base/tree/master/ffi
class LIBJPG

    new: (@filename = filename) =>

    read: =>
        file = io.open @filename, "rb"
        assert file, "Couldn't open JPEG file"

        @rawData = file\read "*a"
        file\close!

    setArguments: =>
        @width       = ffi.new "int[1]"
        @height      = ffi.new "int[1]"
        @jpegSubsamp = ffi.new "int[1]"
        @colorSpace  = ffi.new "int[1]"

    decode: (gray) =>
        @read!

        handle = JPG.tjInitDecompress!
        assert handle, "no TurboJPEG API decompressor handle"

        @setArguments!

        JPG.tjDecompressHeader3 handle, ffi.cast("const unsigned char*", @rawData), #@rawData, @width, @height, @jpegSubsamp, @colorSpace
        assert @width[0] > 0 and @height[0] > 0, "Image dimensions"

        buffer = gray and bff.BUFFER(@width[0], @height[0], 1) or bff.BUFFER @width[0], @height[0], 4
        format = gray and JPG.TJPF_GRAY or JPG.TJPF_RGB

        err = JPG.tjDecompress2(handle, ffi.cast("unsigned char*", @rawData), #@rawData, ffi.cast("unsigned char*", buffer.data), @width[0], buffer.pitch, @height[0], format, 0) == -1
        assert not err, "Decoding error"

        JPG.tjDestroy handle

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

{:LIBJPG}