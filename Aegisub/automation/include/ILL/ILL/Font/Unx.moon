ffi = require "ffi"

has_freetype, freetype = pcall ffi.load, "freetype"
has_fontconfig, fontconfig = pcall ffi.load, "fontconfig"

import C, cast, cdef, new from ffi

-- Set C definitions for freetype / taken from https://github.com/luapower/freetype/blob/master/freetype_h.lua
cdef [[
	void* memset(void *s, int c, size_t n);

	typedef signed int     FT_Int32;
	typedef unsigned int   FT_UInt32;

	typedef signed char    FT_Char;
	typedef unsigned char  FT_Byte;
	typedef char           FT_String;
	typedef signed short   FT_Short;
	typedef unsigned short FT_UShort;
	typedef signed int     FT_Int;
	typedef unsigned int   FT_UInt;
	typedef signed long    FT_Long;
	typedef unsigned long  FT_ULong;
	typedef signed long    FT_Fixed;
	typedef int            FT_Error;
	typedef unsigned char  FT_Bool;

	typedef struct FT_Matrix_ {
		FT_Fixed xx, xy;
		FT_Fixed yx, yy;
	} FT_Matrix;

	typedef void (*FT_Generic_Finalizer)( void* object );

	typedef struct FT_Generic_ {
		void* data;
		FT_Generic_Finalizer finalizer;
	} FT_Generic;

	typedef signed long FT_Pos;

	typedef struct FT_Vector_ {
		FT_Pos x;
		FT_Pos y;
	} FT_Vector;

	typedef struct FT_BBox_ {
		FT_Pos xMin, yMin;
		FT_Pos xMax, yMax;
	} FT_BBox;

	typedef struct FT_Bitmap_ {
		unsigned int rows;
		unsigned int width;
		int pitch;
		unsigned char* buffer;
		unsigned short num_grays;
		unsigned char pixel_mode;
		unsigned char palette_mode;
		void* palette;
	} FT_Bitmap;

	typedef struct FT_Outline_ {
		short n_contours;
		short n_points;
		FT_Vector* points;
		char* tags;
		short* contours;
		int flags;
	} FT_Outline;

	typedef int (*FT_Outline_MoveToFunc) ( const FT_Vector* to, void* user );
	typedef int (*FT_Outline_LineToFunc) ( const FT_Vector* to, void* user );
	typedef int (*FT_Outline_ConicToFunc)( const FT_Vector* control, const FT_Vector* to, void* user );
	typedef int (*FT_Outline_CubicToFunc)( const FT_Vector* control1, const FT_Vector* control2, const FT_Vector* to, void* user );

	typedef struct FT_Outline_Funcs_ {
		FT_Outline_MoveToFunc move_to;
		FT_Outline_LineToFunc line_to;
		FT_Outline_ConicToFunc conic_to;
		FT_Outline_CubicToFunc cubic_to;
		int shift;
		FT_Pos delta;
	} FT_Outline_Funcs;

	typedef enum FT_Glyph_Format_ {
		FT_GLYPH_FORMAT_NONE = ( ( (unsigned long)0 << 24 ) | ( (unsigned long)0 << 16 ) | ( (unsigned long)0 << 8 ) | (unsigned long)0 ),
		FT_GLYPH_FORMAT_COMPOSITE = ( ( (unsigned long)'c' << 24 ) | ( (unsigned long)'o' << 16 ) | ( (unsigned long)'m' << 8 ) | (unsigned long)'p' ),
		FT_GLYPH_FORMAT_BITMAP = ( ( (unsigned long)'b' << 24 ) | ( (unsigned long)'i' << 16 ) | ( (unsigned long)'t' << 8 ) | (unsigned long)'s' ),
		FT_GLYPH_FORMAT_OUTLINE = ( ( (unsigned long)'o' << 24 ) | ( (unsigned long)'u' << 16 ) | ( (unsigned long)'t' << 8 ) | (unsigned long)'l' ),
		FT_GLYPH_FORMAT_PLOTTER = ( ( (unsigned long)'p' << 24 ) | ( (unsigned long)'l' << 16 ) | ( (unsigned long)'o' << 8 ) | (unsigned long)'t' )
	} FT_Glyph_Format;

	typedef struct FT_Glyph_Metrics_ {
		FT_Pos width;
		FT_Pos height;
		FT_Pos horiBearingX;
		FT_Pos horiBearingY;
		FT_Pos horiAdvance;
		FT_Pos vertBearingX;
		FT_Pos vertBearingY;
		FT_Pos vertAdvance;
	} FT_Glyph_Metrics;

	typedef struct FT_Bitmap_Size_ {
		FT_Short height;
		FT_Short width;
		FT_Pos size;
		FT_Pos x_ppem;
		FT_Pos y_ppem;
	} FT_Bitmap_Size;

	typedef struct FT_LibraryRec_ *FT_Library;
	typedef struct FT_DriverRec_* FT_Driver;
	typedef struct FT_FaceRec_* FT_Face;
	typedef struct FT_SizeRec_* FT_Size;
	typedef struct FT_GlyphSlotRec_* FT_GlyphSlot;
	typedef struct FT_CharMapRec_* FT_CharMap;

	typedef enum FT_Encoding_ {
		FT_ENCODING_NONE = ( ( (FT_UInt32)(0) << 24 ) | ( (FT_UInt32)(0) << 16 ) | ( (FT_UInt32)(0) << 8 ) | (FT_UInt32)(0) ),
		FT_ENCODING_MS_SYMBOL = ( ( (FT_UInt32)('s') << 24 ) | ( (FT_UInt32)('y') << 16 ) | ( (FT_UInt32)('m') << 8 ) | (FT_UInt32)('b') ),
		FT_ENCODING_UNICODE = ( ( (FT_UInt32)('u') << 24 ) | ( (FT_UInt32)('n') << 16 ) | ( (FT_UInt32)('i') << 8 ) | (FT_UInt32)('c') ),
		FT_ENCODING_SJIS = ( ( (FT_UInt32)('s') << 24 ) | ( (FT_UInt32)('j') << 16 ) | ( (FT_UInt32)('i') << 8 ) | (FT_UInt32)('s') ),
		FT_ENCODING_PRC = ( ( (FT_UInt32)('g') << 24 ) | ( (FT_UInt32)('b') << 16 ) | ( (FT_UInt32)(' ') << 8 ) | (FT_UInt32)(' ') ),
		FT_ENCODING_BIG5 = ( ( (FT_UInt32)('b') << 24 ) | ( (FT_UInt32)('i') << 16 ) | ( (FT_UInt32)('g') << 8 ) | (FT_UInt32)('5') ),
		FT_ENCODING_WANSUNG = ( ( (FT_UInt32)('w') << 24 ) | ( (FT_UInt32)('a') << 16 ) | ( (FT_UInt32)('n') << 8 ) | (FT_UInt32)('s') ),
		FT_ENCODING_JOHAB = ( ( (FT_UInt32)('j') << 24 ) | ( (FT_UInt32)('o') << 16 ) | ( (FT_UInt32)('h') << 8 ) | (FT_UInt32)('a') ),
		FT_ENCODING_GB2312 = FT_ENCODING_PRC,
		FT_ENCODING_MS_SJIS = FT_ENCODING_SJIS,
		FT_ENCODING_MS_GB2312 = FT_ENCODING_PRC,
		FT_ENCODING_MS_BIG5 = FT_ENCODING_BIG5,
		FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
		FT_ENCODING_MS_JOHAB = FT_ENCODING_JOHAB,
		FT_ENCODING_ADOBE_STANDARD = ( ( (FT_UInt32)('A') << 24 ) | ( (FT_UInt32)('D') << 16 ) | ( (FT_UInt32)('O') << 8 ) | (FT_UInt32)('B') ),
		FT_ENCODING_ADOBE_EXPERT = ( ( (FT_UInt32)('A') << 24 ) | ( (FT_UInt32)('D') << 16 ) | ( (FT_UInt32)('B') << 8 ) | (FT_UInt32)('E') ),
		FT_ENCODING_ADOBE_CUSTOM = ( ( (FT_UInt32)('A') << 24 ) | ( (FT_UInt32)('D') << 16 ) | ( (FT_UInt32)('B') << 8 ) | (FT_UInt32)('C') ),
		FT_ENCODING_ADOBE_LATIN_1 = ( ( (FT_UInt32)('l') << 24 ) | ( (FT_UInt32)('a') << 16 ) | ( (FT_UInt32)('t') << 8 ) | (FT_UInt32)('1') ),
		FT_ENCODING_OLD_LATIN_2 = ( ( (FT_UInt32)('l') << 24 ) | ( (FT_UInt32)('a') << 16 ) | ( (FT_UInt32)('t') << 8 ) | (FT_UInt32)('2') ),
		FT_ENCODING_APPLE_ROMAN = ( ( (FT_UInt32)('a') << 24 ) | ( (FT_UInt32)('r') << 16 ) | ( (FT_UInt32)('m') << 8 ) | (FT_UInt32)('n') )
	} FT_Encoding;

	typedef struct FT_CharMapRec_ {
		FT_Face face;
		union {
			FT_Encoding encoding;
			char _encoding_str[4];
		};
		FT_UShort platform_id;
		FT_UShort encoding_id;
	} FT_CharMapRec;

	typedef struct FT_Face_InternalRec_* FT_Face_Internal;

	typedef struct FT_FaceRec_ {
		FT_Long num_faces;
		FT_Long face_index;
		FT_Long face_flags;
		FT_Long style_flags;
		FT_Long num_glyphs;
		FT_String* family_name;
		FT_String* style_name;
		FT_Int num_fixed_sizes;
		FT_Bitmap_Size* available_sizes;
		FT_Int num_charmaps;
		FT_CharMap* charmaps;
		FT_Generic generic;
		FT_BBox bbox;
		FT_UShort units_per_EM;
		FT_Short ascender;
		FT_Short descender;
		FT_Short height;
		FT_Short max_advance_width;
		FT_Short max_advance_height;
		FT_Short underline_position;
		FT_Short underline_thickness;
		FT_GlyphSlot glyph;
		FT_Size size;
		FT_CharMap charmap;
		FT_Driver driver;
		FT_Generic autohint;
		void* extensions;
		FT_Face_Internal internal;
	} FT_FaceRec;

	typedef struct FT_Size_InternalRec_* FT_Size_Internal;

	typedef struct FT_Size_Metrics_ {
		FT_UShort x_ppem;
		FT_UShort y_ppem;
		FT_Fixed x_scale;
		FT_Fixed y_scale;
		FT_Pos ascender;
		FT_Pos descender;
		FT_Pos height;
		FT_Pos max_advance;
	} FT_Size_Metrics;

	typedef struct FT_SizeRec_ {
		FT_Face face;
		FT_Generic generic;
		FT_Size_Metrics metrics;
		FT_Size_Internal internal;
	} FT_SizeRec;

	typedef struct FT_SubGlyphRec_* FT_SubGlyph;
	typedef struct FT_Slot_InternalRec_* FT_Slot_Internal;

	typedef struct FT_GlyphSlotRec_ {
		FT_Library library;
		FT_Face face;
		FT_GlyphSlot next;
		FT_UInt reserved;
		FT_Generic generic;
		FT_Glyph_Metrics metrics;
		FT_Fixed linearHoriAdvance;
		FT_Fixed linearVertAdvance;
		FT_Vector advance;
		FT_Glyph_Format format;
		FT_Bitmap bitmap;
		FT_Int bitmap_left;
		FT_Int bitmap_top;
		FT_Outline outline;
		FT_UInt num_subglyphs;
		FT_SubGlyph subglyphs;
		void* control_data;
		long control_len;
		FT_Pos lsb_delta;
		FT_Pos rsb_delta;
		void* other;
		FT_Slot_Internal internal;
	} FT_GlyphSlotRec;

	FT_Error FT_Init_FreeType( FT_Library *alibrary );
	FT_Error FT_Done_FreeType( FT_Library library );

	FT_Error FT_New_Face(FT_Library library, const char* filepathname, FT_Long face_index, FT_Face *aface);
	FT_Error FT_Done_Face(FT_Face face);

	typedef enum FT_Size_Request_Type_ {
		FT_SIZE_REQUEST_TYPE_NOMINAL,
		FT_SIZE_REQUEST_TYPE_REAL_DIM,
		FT_SIZE_REQUEST_TYPE_BBOX,
		FT_SIZE_REQUEST_TYPE_CELL,
		FT_SIZE_REQUEST_TYPE_SCALES,
		FT_SIZE_REQUEST_TYPE_MAX
	} FT_Size_Request_Type;

	typedef struct FT_Size_RequestRec_ {
		FT_Size_Request_Type type;
		FT_Long width;
		FT_Long height;
		FT_UInt horiResolution;
		FT_UInt vertResolution;
	} FT_Size_RequestRec;

	typedef struct FT_Size_RequestRec_ *FT_Size_Request;

	FT_Error FT_Request_Size(FT_Face face, FT_Size_Request req);
	FT_Error FT_Load_Glyph(FT_Face face, FT_UInt glyph_index, FT_Int32 load_flags);

	enum {FT_LOAD_DEFAULT = 0x0};

	FT_UInt  FT_Get_Char_Index( FT_Face face, FT_ULong charcode );
	FT_Long  FT_MulFix( FT_Long a, FT_Long b );

	FT_Error FT_Outline_Decompose     ( FT_Outline* outline, const FT_Outline_Funcs* func_interface, void* user );
	void     FT_Outline_Transform     ( const FT_Outline* outline, const FT_Matrix* matrix );
	FT_Error FT_Outline_Embolden      ( FT_Outline* outline, FT_Pos strength );

	// Necessary for the future implementation of the underline and strikeout

	typedef enum FT_Orientation_ {
		FT_ORIENTATION_TRUETYPE = 0,
		FT_ORIENTATION_POSTSCRIPT = 1,
		FT_ORIENTATION_FILL_RIGHT = FT_ORIENTATION_TRUETYPE,
		FT_ORIENTATION_FILL_LEFT = FT_ORIENTATION_POSTSCRIPT,
		FT_ORIENTATION_NONE
	} FT_Orientation;

	FT_Orientation FT_Outline_Get_Orientation( FT_Outline* outline );

	typedef enum  FT_Sfnt_Tag_ {
		FT_SFNT_HEAD,
		FT_SFNT_MAXP,
		FT_SFNT_OS2,
		FT_SFNT_HHEA,
		FT_SFNT_VHEA,
		FT_SFNT_POST,
		FT_SFNT_PCLT,
		FT_SFNT_MAX
	} FT_Sfnt_Tag;

	void* FT_Get_Sfnt_Table( FT_Face face, FT_Sfnt_Tag tag );

	typedef struct  TT_OS2_ {
		FT_UShort  version;                /* 0x0001 - more or 0xFFFF */
		FT_Short   xAvgCharWidth;
		FT_UShort  usWeightClass;
		FT_UShort  usWidthClass;
		FT_UShort  fsType;
		FT_Short   ySubscriptXSize;
		FT_Short   ySubscriptYSize;
		FT_Short   ySubscriptXOffset;
		FT_Short   ySubscriptYOffset;
		FT_Short   ySuperscriptXSize;
		FT_Short   ySuperscriptYSize;
		FT_Short   ySuperscriptXOffset;
		FT_Short   ySuperscriptYOffset;
		FT_Short   yStrikeoutSize;
		FT_Short   yStrikeoutPosition;
		FT_Short   sFamilyClass;

		FT_Byte    panose[10];

		FT_ULong   ulUnicodeRange1;        /* Bits 0-31   */
		FT_ULong   ulUnicodeRange2;        /* Bits 32-63  */
		FT_ULong   ulUnicodeRange3;        /* Bits 64-95  */
		FT_ULong   ulUnicodeRange4;        /* Bits 96-127 */

		FT_Char    achVendID[4];

		FT_UShort  fsSelection;
		FT_UShort  usFirstCharIndex;
		FT_UShort  usLastCharIndex;
		FT_Short   sTypoAscender;
		FT_Short   sTypoDescender;
		FT_Short   sTypoLineGap;
		FT_UShort  usWinAscent;
		FT_UShort  usWinDescent;

		/* only version 1 and higher: */

		FT_ULong   ulCodePageRange1;       /* Bits 0-31   */
		FT_ULong   ulCodePageRange2;       /* Bits 32-63  */

		/* only version 2 and higher: */

		FT_Short   sxHeight;
		FT_Short   sCapHeight;
		FT_UShort  usDefaultChar;
		FT_UShort  usBreakChar;
		FT_UShort  usMaxContext;

		/* only version 5 and higher: */

		FT_UShort  usLowerOpticalPointSize;       /* in twips (1/20 points) */
		FT_UShort  usUpperOpticalPointSize;       /* in twips (1/20 points) */
	} TT_OS2;

	typedef struct  TT_Postscript_
	{
		FT_Fixed  FormatType;
		FT_Fixed  italicAngle;
		FT_Short  underlinePosition;
		FT_Short  underlineThickness;
		FT_ULong  isFixedPitch;
		FT_ULong  minMemType42;
		FT_ULong  maxMemType42;
		FT_ULong  minMemType1;
		FT_ULong  maxMemType1;

		/* Glyph names follow in the 'post' table, but we don't */
		/* load them by default.                                */

	} TT_Postscript;

	typedef struct PS_FontInfoRec_
	{
		FT_String*  version;
		FT_String*  notice;
		FT_String*  full_name;
		FT_String*  family_name;
		FT_String*  weight;
		FT_Long     italic_angle;
		FT_Bool     is_fixed_pitch;
		FT_Short    underline_position;
		FT_UShort   underline_thickness;
	} PS_FontInfoRec;

	FT_Error FT_Get_PS_Font_Info(FT_Face face, PS_FontInfoRec *afont_info);
]]

-- Set C definitions for fontconfig
cdef [[
	typedef void FcConfig;
	typedef void FcPattern;
	typedef struct{
		int nobject;
		int sobject;
		const char** objects;
	} FcObjectSet;
	typedef struct{
		int nfont;
		int sfont;
		FcPattern** fonts;
	} FcFontSet;
	typedef enum{
		FcResultMatchILL,
		FcResultNoMatchILL,
		FcResultTypeMismatchILL,
		FcResultNoIdILL,
		FcResultOutOfMemoryILL
	} FcResult;
	typedef unsigned char FcChar8;
	typedef int FcBool;
	FcConfig* FcInitLoadConfigAndFonts(void);
	FcPattern* FcPatternCreate(void);
	void FcPatternDestroy(FcPattern*);
	FcObjectSet* FcObjectSetBuild(const char*, ...);
	void FcObjectSetDestroy(FcObjectSet*);
	FcFontSet* FcFontList(FcConfig*, FcPattern*, FcObjectSet*);
	void FcFontSetDestroy(FcFontSet*);
	FcResult FcPatternGetString(FcPattern*, const char*, int, FcChar8**);
	FcResult FcPatternGetBool(FcPattern*, const char*, int, FcBool*);
]]

import Math from require "ILL.ILL.Math"
import UTF8 from require "ILL.ILL.UTF8"
import Init from require "ILL.ILL.Font.Init"

OUTLINE_MAX = bit.lshift(1, 28) - 1

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L278
set_font_metrics = (face) ->
	-- Mimicking GDI's behavior for asc/desc/height.
	-- These fields are (apparently) sometimes used for signed values,
	-- despite being unsigned in the spec.
	os2 = cast "TT_OS2*", C.FT_Get_Sfnt_Table face, C.FT_SFNT_OS2
	if os2 and (tonumber(os2.usWinAscent) + tonumber(os2.usWinDescent) != 0)
		face.ascender = tonumber os2.usWinAscent
		face.descender = -tonumber os2.usWinDescent
		face.height = face.ascender - face.descender

	-- If we didn't have usable Win values in the OS/2 table,
	-- then the values from FreeType will still be in these fields.
	-- It'll use either the OS/2 typo metrics or the hhea ones.
	-- If the font has typo metrics but FreeType didn't use them
	-- (either old FT or USE_TYPO_METRICS not set), we'll try those.
	-- In the case of a very broken font that has none of those options,
	-- we fall back on using face.bbox.
	-- Anything without valid OS/2 Win values isn't supported by VSFilter,
	-- so at this point compatibility's out the window and we're just
	-- trying to render _something_ readable.
	if face.ascender - face.descender == 0 or face.height == 0
		if os2 and (tonumber(os2.sTypoAscender) - tonumber(os2.sTypoDescender) != 0)
			face.ascender = tonumber os2.sTypoAscender
			face.descender = tonumber os2.sTypoDescender
			face.height = face.ascender - face.descender
		else
			face.ascender = tonumber face.bbox.yMax
			face.descender = tonumber face.bbox.yMin
			face.height = face.ascender - face.descender

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L507
ass_face_set_size = (face, size) ->
	rq = new "FT_Size_RequestRec"
	C.memset rq, 0, ffi.sizeof rq
	rq.type = C.FT_SIZE_REQUEST_TYPE_REAL_DIM
	rq.width = 0
	rq.height = size * FONT_UPSCALE
	rq.horiResolution = 0
	rq.vertResolution = 0
	freetype.FT_Request_Size face, rq

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L583
ass_font_get_asc_desc = (face) ->
	y_scale = face.size.metrics.y_scale
	ascender = freetype.FT_MulFix face.ascender, y_scale
	descender = freetype.FT_MulFix -face.descender, y_scale
	return tonumber(ascender) / FONT_UPSCALE, tonumber(descender) / FONT_UPSCALE

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L527
ass_face_get_weight = (face) ->
	os2 = cast "TT_OS2*", freetype.FT_Get_Sfnt_Table face, C.FT_SFNT_OS2
	os2Weight = os2 and tonumber(os2.usWeightClass) or 0
	styleFlags = tonumber face.style_flags
	if os2Weight == 0
		return 300 * (styleFlags != 0x1) + 400
	elseif os2Weight >= 1 and os2Weight <= 9
		return os2Weight * 100
	else
		return os2Weight

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L595
ass_glyph_embolden = (slot) ->
	if slot.format != C.FT_GLYPH_FORMAT_OUTLINE
		return
	str = freetype.FT_MulFix(slot.face.units_per_EM, slot.face.size.metrics.y_scale) / FONT_UPSCALE
	freetype.FT_Outline_Embolden slot.outline, str

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L518
ass_face_is_postscript = (face) ->
	postscript_info = new "PS_FontInfoRec[1]"
	err = freetype.FT_Get_PS_Font_Info face, postscript_info
	return err == 0

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L611
ass_glyph_italicize = (slot) ->
	xfrm = new "FT_Matrix", {
		xx: 0x10000
		xy: ass_face_is_postscript(slot.face) and 0x02d24 or 0x05700
		yx: 0x00000
		yy: 0x10000
	}
	freetype.FT_Outline_Transform slot.outline, xfrm

-- https://github.com/libass/libass/blob/5298859c298d3c570d8d7e3b883a0d63490659b8/libass/ass_font.c#L755
ass_get_glyph_outline = (face, has_underline, has_strikeout, addx, addy) ->
	y_scale = tonumber face.size.metrics.y_scale
	adv = tonumber face.glyph.advance.x
	source = face.glyph.outline
	local underline, strikeout
	if adv > 0 and has_underline
		ps = cast "TT_Postscript*", C.FT_Get_Sfnt_Table face, C.FT_SFNT_POST
		if ps and tonumber(ps.underlinePosition) <= 0 and tonumber(ps.underlineThickness) > 0
			underlinePosition = tonumber ps.underlinePosition
			underlineThickness = tonumber ps.underlineThickness
			pos = ((underlinePosition * y_scale) + 0x8000) / 65536
			size = ((underlineThickness * y_scale) + 0x8000) / 65536
			pos = -pos - bit.rshift size, 1
			if pos >= -OUTLINE_MAX and (pos + size) <= OUTLINE_MAX
				underline = {(pos + addy) * FONT_DOWNSCALE, (pos + size + addy) * FONT_DOWNSCALE}
	if adv > 0 and has_strikeout
		os2 = cast "TT_OS2*", C.FT_Get_Sfnt_Table face, C.FT_SFNT_OS2
		if os2 and tonumber(os2.yStrikeoutPosition) >= 0 and tonumber(os2.yStrikeoutSize) > 0
			yStrikeoutPosition = tonumber os2.yStrikeoutPosition
			yStrikeoutSize = tonumber os2.yStrikeoutSize
			pos = ((yStrikeoutPosition * y_scale) + 0x8000) / 65536
			size = ((yStrikeoutSize * y_scale) + 0x8000) / 65536
			pos = -pos - bit.rshift size, 1
			if pos >= -OUTLINE_MAX and (pos + size) <= OUTLINE_MAX
				strikeout = {(pos + addy) * FONT_DOWNSCALE, (pos + size + addy) * FONT_DOWNSCALE}
	dir = freetype.FT_Outline_Get_Orientation source
	iy = dir == C.FT_ORIENTATION_TRUETYPE and 0 or 1
	path = " "
	if underline != nil
		path ..= table.concat {
			"m",
			addx * FONT_DOWNSCALE,
			underline[iy == 0 and 2 or 1],
			(addx + adv) * FONT_DOWNSCALE,
			underline[iy == 0 and 2 or 1],
			(addx + adv) * FONT_DOWNSCALE,
			underline[iy == 0 and 1 or 2],
			addx * FONT_DOWNSCALE,
			underline[iy == 0 and 1 or 2],
		}, " "
	if strikeout != nil
		path ..= table.concat {
			"m",
			addx * FONT_DOWNSCALE,
			strikeout[iy == 0 and 2 or 1],
			(addx + adv) * FONT_DOWNSCALE,
			strikeout[iy == 0 and 2 or 1],
			(addx + adv) * FONT_DOWNSCALE,
			strikeout[iy == 0 and 1 or 2],
			addx * FONT_DOWNSCALE,
			strikeout[iy == 0 and 1 or 2],
		}, " "
	return path

class FreeType extends Init

	init: =>
		unless has_freetype
			error "freetype library couldn't be loaded", 2

		-- Check that the font has a bold and italic variant if necessary
		@found_bold, @found_italic = false, false

		-- Get the font path
		font_path = @getFontPath!
		unless font_path
			error "Couldn't find #{@family} among your fonts"

		-- Init FreeType
		@library = new "FT_Library[1]"
		err = freetype.FT_Init_FreeType @library

		if err != 0
			error "Failed to load freetype library"

		ffi.gc @library, (lib) -> freetype.FT_Done_FreeType lib[0]

		-- Load font face
		@face = new "FT_Face[1]"
		err = freetype.FT_New_Face @library[0], font_path, 0, @face

		if err != 0
			error "Failed to load freetype face"

		ffi.gc @face, (face) -> freetype.FT_Done_Face face[0]

		set_font_metrics @face[0]
		ass_face_set_size @face[0], @size

		@ascender, @descender = ass_font_get_asc_desc @face[0]
		@height = @ascender + @descender
		@weight = tonumber ass_face_get_weight @face[0]

	-- Callback to access the glyphs for each character
	callBackChars: (text, callback) =>
		face_size = @face[0].size.face
		width, height = 0, 0
		for ci, char in UTF8(text)\chars!
			glyph_index = freetype.FT_Get_Char_Index face_size, UTF8.charcodepoint char
			err = freetype.FT_Load_Glyph face_size, glyph_index, C.FT_LOAD_DEFAULT
			if err != 0
				error "Failed to load the freetype glyph", 2
			callback ci, char, face_size.glyph
		return true

	-- Get font metrics
	getMetrics: =>
		{
			ascent: @ascender * @yscale
			descent: @descender * @yscale
			height: @height * @yscale
			internal_leading: (@ascender - @descender - (@face[0].units_per_EM / FONT_UPSCALE)) * @yscale
			external_leading: 0
		}

	-- Get text extents
	getTextExtents: (text) =>
		face_size, width = @face[0].size.face, 0
		@callBackChars text, (ci, char, glyph) ->
			width += tonumber(glyph.metrics.horiAdvance) + (@hspace * FONT_UPSCALE)
		{
			width: (width / FONT_UPSCALE) * @xscale
			height: @height * @yscale
		}

	-- Converts text to ASS shape
	getTextToShape: (text) =>
		paths, x = {}, 0
		@callBackChars text, (ci, char, glyph) ->
			build, path = {}, {}
			-- FIXME
			if @bold and @weight < 700 and not @found_bold
				ass_glyph_embolden glyph
			if @italic and not @found_italic
				ass_glyph_italicize glyph
			-- move the outline points to the correct position
			for i = 0, glyph.outline.n_points - 1
				glyph.outline.points[i].x += x
				glyph.outline.points[i].y = (glyph.outline.points[i].y * -1) + @ascender * FONT_UPSCALE
			-- callbacks for outline decomposition
			move_to = (to, user) ->
				table.insert build, {
					"m"
					tonumber(to.x) * FONT_DOWNSCALE
					tonumber(to.y) * FONT_DOWNSCALE
				}
				return 0
			line_to = (to, user) ->
				table.insert build, {
					"l"
					tonumber(to.x) * FONT_DOWNSCALE
					tonumber(to.y) * FONT_DOWNSCALE
				}
				return 0
			conic_to = (control, to, user) ->
				table.insert build, {
					"c"
					tonumber(control.x) * FONT_DOWNSCALE
					tonumber(control.y) * FONT_DOWNSCALE
					tonumber(to.x) * FONT_DOWNSCALE
					tonumber(to.y) * FONT_DOWNSCALE
				}
				return 0
			cubic_to = (control1, control2, to, user) ->
				table.insert build, {
					"b"
					tonumber(control1.x) * FONT_DOWNSCALE
					tonumber(control1.y) * FONT_DOWNSCALE
					tonumber(control2.x) * FONT_DOWNSCALE
					tonumber(control2.y) * FONT_DOWNSCALE
					tonumber(to.x) * FONT_DOWNSCALE
					tonumber(to.y) * FONT_DOWNSCALE
				}
				return 0
			-- Define outline functions
			outline_funcs = new "FT_Outline_Funcs[1]"
			outline_funcs[0].move_to = cast "FT_Outline_MoveToFunc", move_to
			outline_funcs[0].line_to = cast "FT_Outline_LineToFunc", line_to
			outline_funcs[0].conic_to = cast "FT_Outline_ConicToFunc", conic_to
			outline_funcs[0].cubic_to = cast "FT_Outline_CubicToFunc", cubic_to
			-- Decompose outline
			err = freetype.FT_Outline_Decompose glyph.outline, outline_funcs, nil
			if err != 0
				error "Failed to load the freetype outline decompose", 2
			-- Frees up memory stored for callbacks
			outline_funcs[0].move_to\free!
			outline_funcs[0].line_to\free!
			outline_funcs[0].conic_to\free!
			outline_funcs[0].cubic_to\free!
			-- Converts quadratic curves to bezier
			for i = 1, #build
				val = build[i]
				if val[1] == "c"
					lst = build[i - 1]
					p1x = lst[#lst - 1]
					p1y = lst[#lst]
					p4x = val[4]
					p4y = val[5]
					p2x = p1x + 2/3 * (val[2] - p1x)
					p2y = p1y + 2/3 * (val[3] - p1y)
					p3x = p4x + 2/3 * (val[2] - p4x)
					p3y = p4y + 2/3 * (val[3] - p4y)
					build[i] = {"b", p2x, p2y, p3x, p3y, p4x, p4y}
				path[i] = table.concat build[i], " "
			table.insert paths, table.concat path, " "
			if @underline or @strikeout
				table.insert paths, ass_get_glyph_outline @face[0], @underline, @strikeout, x, @ascender * FONT_UPSCALE
			x += tonumber(glyph.metrics.horiAdvance) + (@hspace * FONT_UPSCALE)
		return table.concat paths, " "

	-- Gets the complete list of fonts available on the system
	getFonts: =>
		-- Check whether or not the fontconfig library was loaded
		unless has_fontconfig
			error "fontconfig library couldn't be loaded", 2
		-- Get fonts list from fontconfig
		fontset = ffi.gc fontconfig.FcFontList(fontconfig.FcInitLoadConfigAndFonts(), ffi.gc(fontconfig.FcPatternCreate(), fontconfig.FcPatternDestroy), ffi.gc(fontconfig.FcObjectSetBuild("family", "fullname", "style", "outline", "file", nil), fontconfig.FcObjectSetDestroy)), fontconfig.FcFontSetDestroy
		local font, family, fullname, style, outline, file, cstr, cbool
		cstr = new "FcChar8*[1]"
		cbool = new "FcBool[1]"
		fonts = {n: 0}
		for i = 0, fontset[0].nfont - 1
			font = fontset[0].fonts[i]
			family, fullname, style, outline, file = nil, nil, nil, nil, nil
			if fontconfig.FcPatternGetString(font, "family", 0, cstr) == C.FcResultMatchILL
				family = ffi.string cstr[0]
			if fontconfig.FcPatternGetString(font, "fullname", 0, cstr) == C.FcResultMatchILL
				fullname = ffi.string cstr[0]
			if fontconfig.FcPatternGetString(font, "style", 0, cstr) == C.FcResultMatchILL
				style = ffi.string cstr[0]
			if fontconfig.FcPatternGetBool(font, "outline", 0, cbool) == C.FcResultMatchILL
				outline = cbool[0]
			if fontconfig.FcPatternGetString(font, "file", 0, cstr) == C.FcResultMatchILL
				file = ffi.string cstr[0]
			if family and fullname and style and outline
				fonts.n += 1
				fonts[fonts.n] = {
					name: family
					longname: fullname
					style: style
					type: outline == 0 and "Raster" or "Outline"
					path: file
				}
		-- Order fonts by name & style
		table.sort fonts, (font1, font2) ->
			if font1.name == font2.name
				return font1.style < font2.style
			else
				return font1.name < font2.name
		-- Return collected fonts
		return fonts

	-- Gets the directory path of the fonts
	getFontPath: =>
		fonts = @getFonts!
		font_variants = {}

		-- Collect all fonts matching the requested family
		for font in *fonts
			if font.name\lower! == @family\lower!
				table.insert font_variants, font

		if #font_variants == 0
			return false

		style_preference = {
			["bold italic"]: 1
			["bold oblique"]: 2
			["italic"]: 3
			["oblique"]: 4
			["bold"]: 5
			["regular"]: 6
			["normal"]: 7
		}

		-- Sort fonts by style preference
		table.sort font_variants, (a, b) ->
			a_style = a.style\lower!
			b_style = b.style\lower!
			a_pref = style_preference[a_style] or 99
			b_pref = style_preference[b_style] or 99
			return a_pref < b_pref

		-- Find the best match based on requested styles
		for font in *font_variants
			style = font.style\lower!
			is_bold = style\find("bold") != nil
			is_italic = (style\find("italic") or style\find("oblique")) != nil
			if @bold == is_bold and @italic == is_italic
				@found_bold = is_bold
				@found_italic = is_italic
				return font.path

		-- If no exact match, return the first variant
		first_font = font_variants[1]
		@found_bold = first_font.style\lower!\find("bold") != nil
		@found_italic = first_font.style\lower!\find("italic") != nil or first_font.style\lower!\find("oblique") != nil
		return first_font.path

{:FreeType}