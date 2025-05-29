ffi = require "ffi"
advapi = ffi.load "Advapi32"

import C, cdef, gc, new, cast from ffi

cdef [[
	enum{CP_UTF8_ILL = 65001};
	enum{MM_TEXT_ILL = 1};
	enum{TRANSPARENT_ILL = 1};
	enum{
		FW_NORMAL_ILL = 400,
		FW_BOLD_ILL = 700
	};
	enum{DEFAULT_CHARSET_ILL = 1};
	enum{OUT_TT_PRECIS_ILL = 4};
	enum{CLIP_DEFAULT_PRECIS_ILL = 0};
	enum{ANTIALIASED_QUALITY_ILL = 4};
	enum{DEFAULT_PITCH_ILL = 0x0};
	enum{FF_DONTCARE_ILL = 0x0};
	enum{
		PT_MOVETO_ILL = 0x6,
		PT_LINETO_ILL = 0x2,
		PT_BEZIERTO_ILL = 0x4,
		PT_CLOSEFIGURE_ILL = 0x1
	};
	typedef unsigned int UINT;
	typedef unsigned long DWORD;
	typedef DWORD* LPDWORD;
	typedef const char* LPCSTR;
	typedef const wchar_t* LPCWSTR;
	typedef wchar_t* LPWSTR;
	typedef char* LPSTR;
	typedef void* HANDLE;
	typedef HANDLE HDC;
	typedef int BOOL;
	typedef BOOL* LPBOOL;
	typedef unsigned int size_t;
	typedef HANDLE HFONT;
	typedef HANDLE HGDIOBJ;
	typedef long LONG;
	typedef wchar_t WCHAR;
	typedef unsigned char BYTE;
	typedef BYTE* LPBYTE;
	typedef int INT;
	typedef long LPARAM;
	static const int LF_FACESIZE_ILL = 32;
	static const int LF_FULLFACESIZE_ILL = 64;
	typedef struct{
		LONG tmHeight;
		LONG tmAscent;
		LONG tmDescent;
		LONG tmInternalLeading;
		LONG tmExternalLeading;
		LONG tmAveCharWidth;
		LONG tmMaxCharWidth;
		LONG tmWeight;
		LONG tmOverhang;
		LONG tmDigitizedAspectX;
		LONG tmDigitizedAspectY;
		WCHAR tmFirstChar;
		WCHAR tmLastChar;
		WCHAR tmDefaultChar;
		WCHAR tmBreakChar;
		BYTE tmItalic;
		BYTE tmUnderlined;
		BYTE tmStruckOut;
		BYTE tmPitchAndFamily;
		BYTE tmCharSet;
	}TEXTMETRICW, *LPTEXTMETRICW;
	typedef struct{
		LONG cx;
		LONG cy;
	}SIZE, *LPSIZE;
	typedef struct{
		LONG left;
		LONG top;
		LONG right;
		LONG bottom;
	}RECT;
	typedef const RECT* LPCRECT;
	typedef struct{
		LONG x;
		LONG y;
	}POINT, *LPPOINT;
	typedef struct{
		LONG  lfHeight;
		LONG  lfWidth;
		LONG  lfEscapement;
		LONG  lfOrientation;
		LONG  lfWeight;
		BYTE  lfItalic;
		BYTE  lfUnderline;
		BYTE  lfStrikeOut;
		BYTE  lfCharSet;
		BYTE  lfOutPrecision;
		BYTE  lfClipPrecision;
		BYTE  lfQuality;
		BYTE  lfPitchAndFamily;
		WCHAR lfFaceName[LF_FACESIZE_ILL];
	}LOGFONTW, *LPLOGFONTW;
	typedef struct{
		LOGFONTW elfLogFont;
		WCHAR   elfFullName[LF_FULLFACESIZE_ILL];
		WCHAR   elfStyle[LF_FACESIZE_ILL];
		WCHAR   elfScript[LF_FACESIZE_ILL];
	}ENUMLOGFONTEXW, *LPENUMLOGFONTEXW;
	enum{
		FONTTYPE_RASTER_ILL = 1,
		FONTTYPE_DEVICE_ILL = 2,
		FONTTYPE_TRUETYPE_ILL = 4
	};
	typedef int (__stdcall *FONTENUMPROC)(const ENUMLOGFONTEXW*, const void*, DWORD, LPARAM);
	enum{ERROR_SUCCESS_ILL = 0};
	typedef HANDLE HKEY;
	typedef HKEY* PHKEY;
	enum{HKEY_LOCAL_MACHINE_ILL = 0x80000002};
	typedef enum{KEY_READ_ILL = 0x20019}REGSAM;
	int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
	int WideCharToMultiByte(UINT, DWORD, LPCWSTR, int, LPSTR, int, LPCSTR, LPBOOL);
	HDC CreateCompatibleDC(HDC);
	BOOL DeleteDC(HDC);
	int SetMapMode(HDC, int);
	int SetBkMode(HDC, int);
	size_t wcslen(const wchar_t*);
	HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
	HGDIOBJ SelectObject(HDC, HGDIOBJ);
	BOOL DeleteObject(HGDIOBJ);
	BOOL GetTextMetricsW(HDC, LPTEXTMETRICW);
	BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
	BOOL BeginPath(HDC);
	BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const INT*);
	BOOL EndPath(HDC);
	int GetPath(HDC, LPPOINT, LPBYTE, int);
	BOOL AbortPath(HDC);
	int EnumFontFamiliesExW(HDC, LPLOGFONTW, FONTENUMPROC, LPARAM, DWORD);
	LONG RegOpenKeyExA(HKEY, LPCSTR, DWORD, REGSAM, PHKEY);
	LONG RegCloseKey(HKEY);
	LONG RegEnumValueW(HKEY, DWORD, LPWSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);
]]

import Init from require "ILL.ILL.Font.Init"
import Math from require "ILL.ILL.Math"

utf8_to_utf16 = (s) ->
	-- Get resulting utf16 characters number (+ null-termination)
	wlen = C.MultiByteToWideChar C.CP_UTF8_ILL, 0x0, s, -1, nil, 0
	-- Allocate array for utf16 characters storage
	ws = new "wchar_t[?]", wlen
	-- Convert utf8 string to utf16 characters
	C.MultiByteToWideChar C.CP_UTF8_ILL, 0x0, s, -1, ws, wlen
	-- Return utf16 C string
	return ws

utf16_to_utf8 = (ws) ->
	-- Get resulting utf8 characters number (+ null-termination)
	slen = C.WideCharToMultiByte C.CP_UTF8_ILL, 0x0, ws, -1, nil, 0, nil, nil
	-- Allocate array for utf8 characters storage
	s = new "char[?]", slen
	-- Convert utf16 string to utf8 characters
	C.WideCharToMultiByte C.CP_UTF8_ILL, 0x0, ws, -1, s, slen, nil, nil
	-- Return utf8 Lua string
	return ffi.string s

class WindowsGDI extends Init

	init: =>
		-- Create device context and set light resources deleter
		local resources_deleter
		@dc = gc C.CreateCompatibleDC(nil), ->
			resources_deleter!
			return

		-- Set context coordinates mapping mode
		C.SetMapMode @dc, C.MM_TEXT_ILL

		-- Set context backgrounds to transparent
		C.SetBkMode @dc, C.TRANSPARENT_ILL

		-- Convert family from utf8 to utf16
		family = utf8_to_utf16 @family

		-- Fix family length
		lfFaceName = ffi.new "WCHAR[?]", FONT_LF_FACESIZE
		familyLen = tonumber C.wcslen family
		if familyLen >= FONT_LF_FACESIZE
			ffi.copy lfFaceName, family, (FONT_LF_FACESIZE-1) * ffi.sizeof "WCHAR"
		else
			ffi.copy lfFaceName, family, (familyLen+1) * ffi.sizeof "WCHAR"

		-- Create font handle
		font = C.CreateFontW @size * FONT_UPSCALE, 0, 0, 0, @bold and C.FW_BOLD_ILL or C.FW_NORMAL_ILL, @italic and 1 or 0, @underline and 1 or 0, @strikeout and 1 or 0, C.DEFAULT_CHARSET_ILL, C.OUT_TT_PRECIS_ILL, C.CLIP_DEFAULT_PRECIS_ILL, C.ANTIALIASED_QUALITY_ILL, C.DEFAULT_PITCH_ILL + C.FF_DONTCARE_ILL, lfFaceName

		-- Set new font to device context
		old_font = C.SelectObject @dc, font

		-- Define light resources deleter
		resources_deleter = ->
			C.SelectObject @dc, old_font
			C.DeleteObject font
			C.DeleteDC @dc
			return

		@dx = FONT_DOWNSCALE * @xscale
		@dy = FONT_DOWNSCALE * @yscale

	-- Get font metrics
	getMetrics: =>
		-- Get font metrics from device context
		metrics = new "TEXTMETRICW[1]"
		C.GetTextMetricsW @dc, metrics
		{:tmHeight, :tmAscent, :tmDescent, :tmInternalLeading, :tmExternalLeading} = metrics[0]
		{:dy} = @
		return {
			height: tmHeight * dy
			ascent: tmAscent * dy
			descent: tmDescent * dy
			internal_leading: tmInternalLeading * dy
			external_leading: tmExternalLeading * dy
		}

	-- Get text extents
	getTextExtents: (text) =>
		-- Get utf16 text
		tx = utf8_to_utf16 text
		text_len = tonumber C.wcslen tx

		-- Get text extents with this font
		sz = new "SIZE[1]"
		C.GetTextExtentPoint32W @dc, tx, text_len, sz
		{:cx, :cy} = sz[0]
		{
			width: (cx * FONT_DOWNSCALE + @hspace * text_len) * @xscale
			height: cy * @dy
		}

	-- Converts text to ASS shape
	getTextToShape: (text, precision = 3) =>
		-- Initialize shape as table
		shape, insert, round = {}, table.insert, Math.round

		-- Get utf16 text
		tx = utf8_to_utf16 text
		text_len = tonumber C.wcslen tx

		-- Add path to device context
		if text_len > 8192
			error "text too long", 2

		local char_widths
		if @hspace != 0
			char_widths = new "INT[?]", text_len
			size = new "SIZE[1]"
			space = @hspace * FONT_UPSCALE
			for i = 0, text_len - 1
				C.GetTextExtentPoint32W @dc, tx + i, 1, size
				char_widths[i] = size[0].cx + space

		-- Inits path
		C.BeginPath @dc
		C.ExtTextOutW @dc, 0, 0, 0x0, nil, tx, text_len, char_widths
		C.EndPath @dc

		-- Get path data
		points_n = C.GetPath @dc, nil, nil, 0

		if points_n > 0
			{:dx, :dy} = @
			points = new "POINT[?]", points_n
			types = new "BYTE[?]", points_n
			C.GetPath @dc, points, types, points_n
			-- Convert points to shape
			i, last_type, curr_type, curr_point = 0, nil, nil, nil
			while i < points_n
				curr_type, curr_point = types[i], points[i]
				if curr_type == C.PT_MOVETO_ILL
					if last_type != C.PT_MOVETO_ILL
						insert shape, "m"
						last_type = curr_type
					{:x, :y} = curr_point
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					i += 1
				elseif curr_type == C.PT_LINETO_ILL or curr_type == C.PT_LINETO_ILL + C.PT_CLOSEFIGURE_ILL
					if last_type != C.PT_LINETO_ILL
						insert shape, "l"
						last_type = curr_type
					{:x, :y} = curr_point
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					i += 1
				elseif curr_type == C.PT_BEZIERTO_ILL or curr_type == C.PT_BEZIERTO_ILL + C.PT_CLOSEFIGURE_ILL
					if last_type != C.PT_BEZIERTO_ILL
						insert shape, "b"
						last_type = curr_type
					{:x, :y} = curr_point
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					{:x, :y} = points[i + 1]
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					{:x, :y} = points[i + 2]
					insert shape, round x * dx, precision
					insert shape, round y * dy, precision
					i += 3
				else -- invalid type (should never happen, but let us be safe)
					i += 1
			-- Clear device context path
			C.AbortPath @dc
		-- Return shape as string
		return table.concat shape, " "

	-- Lists available system fonts
	getFonts: (with_filenames) ->
		fonts = {n: 0}
		plogfont = new "LOGFONTW[1]"
		plogfont[0].lfCharSet = C.DEFAULT_CHARSET_ILL
		plogfont[0].lfFaceName[0] = 0
		plogfont[0].lfPitchAndFamily = C.DEFAULT_PITCH_ILL + C.FF_DONTCARE_ILL
		local name, style, font
		fn = (penumlogfont, _, fonttype, _) ->
			-- Skip different font charsets
			name = utf16_to_utf8 penumlogfont[0].elfLogFont.lfFaceName
			style = utf16_to_utf8 penumlogfont[0].elfStyle
			win_font_found = false
			for i = 1, fonts.n
				font = fonts[i]
				if font.name == name and font.style == style
					win_font_found = true
					break
			unless win_font_found
				fonts.n += 1
				longname = utf16_to_utf8 penumlogfont[0].elfFullName
				__type = fonttype == C.FONTTYPE_RASTER_ILL and "Raster" or fonttype == C.FONTTYPE_DEVICE_ILL and "Device" or fonttype == C.FONTTYPE_TRUETYPE_ILL and "TrueType" or "Unknown"
				fonts[fonts.n] = {:style, :name, :longname, type: __type}
			return 1
		dc = gc C.CreateCompatibleDC(nil), C.DeleteDC
		C.EnumFontFamiliesExW dc, plogfont, fn, 0, 0
		if with_filenames
			file_to_font = (fontname, fontfile) ->
				for i = 1, fonts.n do
					font = fonts[i]
					if fontname == font.name\gsub("^@", "", 1) or fontname == ("%s %s")\format(font.name\gsub("^@", "", 1), font.style) or fontname == font.longname\gsub("^@", "", 1)
						font.file = fontfile
			-- Search registry for font files
			fontfile = nil
			pregkey = new "HKEY[1]"
			hk = cast "HKEY", C.HKEY_LOCAL_MACHINE_ILL
			if advapi.RegOpenKeyExA(hk, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts", 0, C.KEY_READ_ILL, pregkey) == C.ERROR_SUCCESS_ILL
				regkey = gc pregkey[0], advapi.RegCloseKey
				value_index = 0
				value_name = new "wchar_t[16383]"
				pvalue_name_size = new "DWORD[1]"
				value_data = new "BYTE[65536]"
				pvalue_data_size = new "DWORD[1]"
				while true
					pvalue_name_size[0] = ffi.sizeof(value_name) / ffi.sizeof "wchar_t"
					pvalue_data_size[0] = ffi.sizeof value_data
					if advapi.RegEnumValueW(regkey, value_index, value_name, pvalue_name_size, nil, nil, value_data, pvalue_data_size) != C.ERROR_SUCCESS_ILL
						break
					else
						value_index += 1
					fontname = utf16_to_utf8(value_name)\gsub "(.*) %(.-%)$", "%1", 1
					fontfile = utf16_to_utf8 ffi.cast "wchar_t*", value_data
					file_to_font fontname, fontfile
					if fontname\find " & "
						for fontname in fontname\gmatch "(.-) & "
							file_to_font fontname, fontfile
						file_to_font fontname\match(".* & (.-)$"), fontfile
		-- Order fonts by name & style
		table.sort fonts, (a, b) ->
			if a.name == b.name
				a.style < b.style
			else
				a.name < b.name
		-- Return collected fonts
		return fonts

{:WindowsGDI}