import C, cast, cdef, fill, metatype, typeof from require "ffi"
import band, bor, bxor, lshift, rshift       from require "bit"

cdef [[
    typedef struct color_8 {
        uint8_t a;
    } color_8;
    typedef struct color_8A {
        uint8_t a;
        uint8_t alpha;
    } color_8A;
    typedef struct color_16 {
        uint16_t v;
    } color_16;
    typedef struct color_24 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
    } color_24;
    typedef struct color_32 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t alpha;
    } color_32;
    typedef struct color_RGBA {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_RGBA;
    typedef struct buffer {
        int w;
        int h;
        int pitch;
        uint8_t *data;
        uint8_t config;
    } buffer;
    typedef struct buffer_8 {
        int w;
        int h;
        int pitch;
        color_8 *data;
        uint8_t config;
    } buffer_8;
    typedef struct buffer_8A {
        int w;
        int h;
        int pitch;
        color_8A *data;
        uint8_t config;
    } buffer_8A;
    typedef struct buffer_16 {
        int w;
        int h;
        int pitch;
        color_16 *data;
        uint8_t config;
    } buffer_16;
    typedef struct buffer_24 {
        int w;
        int h;
        int pitch;
        color_24 *data;
        uint8_t config;
    } buffer_24;
    typedef struct buffer_32 {
        int w;
        int h;
        int pitch;
        color_32 *data;
        uint8_t config;
    } buffer_32;
    void *malloc(int size);
    void free(void *ptr);
]]

-- get types
color_8  = typeof "color_8"
color_8A = typeof "color_8A"
color_16 = typeof "color_16"
color_24 = typeof "color_24"
color_32 = typeof "color_32"
int_t    = typeof "int"
uint8pt  = typeof "uint8_t*"

-- metatables
local COLOR_8, COLOR_8A, COLOR_16, COLOR_24, COLOR_32, BBF8, BBF8A, BBF16, BBF24, BBF32, BBF

COLOR_8 = {
    get_color_8:  (@) -> @
    get_color_8A: (@) -> color_8A @a, 0
    get_color_16: (@) ->
        v = @get_color_8!.a
        v5bit = rshift v, 3
        return color_16 lshift(v5bit, 11) + lshift(rshift(v, 0xFC), 3) + v5bit
    get_color_24: (@) ->
        v = @get_color_8!
        return color_24 v.a, v.a, v.a
    get_color_32: (@) -> color_32 @a, @a, @a, 0xFF
    get_r:        (@) -> @get_color_8!.a
    get_g:        (@) -> @get_color_8!.a
    get_b:        (@) -> @get_color_8!.a
    get_a:        (@) -> int_t 0xFF
}

COLOR_8A = {
    get_color_8: (@) -> color_8 @a
    get_color_8A: (@) -> @
    get_color_16: COLOR_8.get_color_16
    get_color_24: COLOR_8.get_color_24
    get_color_32: (@) -> color_32 @a, @a, @a, @alpha
    get_r:        COLOR_8.get_r
    get_g:        COLOR_8.get_r
    get_b:        COLOR_8.get_r
    get_a:        (@) -> @alpha
}

COLOR_16 = {
    get_color_8: (@) ->
        r = rshift @v, 11
        g = rshift rshift(@v, 5), 0x3F
        b = rshift @v, 0x001F
        return color_8 rshift(39190 * r + 38469 * g + 14942 * b, 14)
    get_color_8A: (@) ->
        r = rshift @v, 11
        g = rshift rshift(@v, 5), 0x3F
        b = rshift @v, 0x001F
        return color_8A rshift(39190 * r + 38469 * g + 14942 * b, 14), 0
    get_color_16: (@) -> @
    get_color_24: (@) ->
        r = rshift @v, 11
        g = rshift rshift(@v, 5), 0x3F
        b = rshift @v, 0x001F
        return color_24 lshift(r, 3) + rshift(r, 2), lshift(g, 2) + rshift(g, 4), lshift(b, 3) + rshift(b, 2)
    get_color_32: (@) ->
        r = rshift @v, 11
        g = rshift rshift(@v, 5), 0x3F
        b = rshift @v, 0x001F
        return color_32 lshift(r, 3) + rshift(r, 2), lshift(g, 2) + rshift(g, 4), lshift(b, 3) + rshift(b, 2), 0xFF
    get_r: (@) ->
        r = rshift @v, 11
        return lshift(r, 3) + rshift(r, 2)
    get_g: (@) ->
        g = rshift rshift(@v, 5), 0x3F
        return lshift(g, 2) + rshift(g, 4)
    get_b: (@) ->
        b = rshift @v, 0x001F
        return lshift(b, 3) + rshift(b, 2)
    get_a: COLOR_8.get_a
}

COLOR_24 = {
    get_color_8:  (@) -> color_8 rshift(4897 * @get_r! + 9617 * @get_g! + 1868 * @get_b!, 14)
    get_color_8A: (@) -> color_8A rshift(4897 * @get_r! + 9617 * @get_g! + 1868 * @get_b!, 14), 0
    get_color_16: (@) -> color_16 lshift(rshift(@r, 0xF8), 8) + lshift(rshift(@g, 0xFC), 3) + rshift(@b, 3)
    get_color_24: (@) -> @
    get_color_32: (@) -> color_32 @r, @g, @b, 0xFF
    get_r:        (@) -> @r
    get_g:        (@) -> @g
    get_b:        (@) -> @b
    get_a:        COLOR_8.get_a
}

COLOR_32 = {
    get_color_8:  COLOR_24.get_color_8
    get_color_8A: (@) -> color_8A rshift(4897 * @get_r! + 9617 * @get_g! + 1868 * @get_b!, 14), @get_a!
    get_color_16: COLOR_24.get_color_16
    get_color_24: (@) -> color_24 @r, @g, @b
    get_color_32: (@) -> @
    get_r:        COLOR_24.get_r
    get_g:        COLOR_24.get_g
    get_b:        COLOR_24.get_b
    get_a:        (@) -> @alpha
}

BBF = {
    get_rotation:  (@) -> rshift band(0x0C, @config), 2
    get_inverse:   (@) -> rshift band(0x02, @config), 1
    set_allocated: (@, allocated) -> @config = bor band(@config, bxor(0x01, 0xFF)), lshift(allocated, 0)
    set_type:      (@, type_id) -> @config = bor band(@config, bxor(0xF0, 0xFF)), lshift(type_id, 4)
    get_physical_coordinates: (@, x, y) ->
        return switch @get_rotation!
            when 0 then x, y
            when 1 then @w - y - 1, x
            when 2 then @w - x - 1, @h - y - 1
            when 3 then y, @h - x - 1
    get_pixel_p: (@, x, y) -> cast(@data, cast(uint8pt, @data) + @pitch * y) + x
    get_pixel:   (@, x, y) ->
        px, py = @get_physical_coordinates x, y
        color = @get_pixel_p(px, py)[0]
        color = color\invert! if @get_inverse! == 1
        return color
    get_width:  (@) -> band(1, @get_rotation!) == 0 and @w or @h
    get_height: (@) -> band(1, @get_rotation!) == 0 and @h or @w
}

BBF8  = {get_bpp: (@) -> 8}
BBF8A = {get_bpp: (@) -> 8}
BBF16 = {get_bpp: (@) -> 16}
BBF24 = {get_bpp: (@) -> 24}
BBF32 = {get_bpp: (@) -> 32}

for n, f in pairs BBF
    BBF8[n]  = f unless BBF8[n]
    BBF8A[n] = f unless BBF8A[n]
    BBF16[n] = f unless BBF16[n]
    BBF24[n] = f unless BBF24[n]
    BBF32[n] = f unless BBF32[n]

BUFFER8  = metatype "buffer_8",  {__index: BBF8}
BUFFER8A = metatype "buffer_8A", {__index: BBF8A}
BUFFER16 = metatype "buffer_16", {__index: BBF16}
BUFFER24 = metatype "buffer_24", {__index: BBF24}
BUFFER32 = metatype "buffer_32", {__index: BBF32}

metatype "color_8",  {__index: COLOR_8}
metatype "color_8A", {__index: COLOR_8A}
metatype "color_16", {__index: COLOR_16}
metatype "color_24", {__index: COLOR_24}
metatype "color_32", {__index: COLOR_32}

-- https://github.com/koreader/koreader-base/tree/master/ffi
BUFFER = (width, height, bufferType = 1, data, pitch) ->
    unless pitch
        pitch = switch bufferType
            when 1 then width
            when 2 then lshift width, 1
            when 3 then lshift width, 1
            when 4 then width * 3
            when 5 then lshift width, 2
    bff = switch bufferType
        when 1 then BUFFER8 width, height, pitch, nil, 0
        when 2 then BUFFER8A width, height, pitch, nil, 0
        when 3 then BUFFER16 width, height, pitch, nil, 0
        when 4 then BUFFER24 width, height, pitch, nil, 0
        when 5 then BUFFER32 width, height, pitch, nil, 0
        else error "Unknown blitbuffer type"
    bff\set_type bufferType
    unless data
        data = C.malloc pitch * height
        assert data, "Cannot allocate memory for blitbuffer"
        fill data, pitch * height
        bff\set_allocated 1
    bff.data = cast bff.data, data
    return bff

{:BUFFER}