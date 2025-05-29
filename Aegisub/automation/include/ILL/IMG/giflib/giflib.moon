ffi = require "ffi"
requireffi = require "requireffi.requireffi"

has_loaded, GIF = pcall requireffi, "ILL.IMG.giflib.giflib.giflib"

ffi.cdef [[
	typedef unsigned char GifByteType;
	typedef int GifWord;
	typedef struct GifColorType {
		GifByteType Red, Green, Blue;
	} GifColorType;
	typedef struct ColorMapObject {
		int ColorCount;
		int BitsPerPixel;
		_Bool SortFlag;
		GifColorType *Colors;
	} ColorMapObject;
	typedef struct GifImageDesc {
		GifWord Left, Top, Width, Height;
		_Bool Interlace;
		ColorMapObject *ColorMap;
	} GifImageDesc;
	typedef struct ExtensionBlock {
		int ByteCount;
		GifByteType *Bytes;
		int Function;
	} ExtensionBlock;
	typedef struct SavedImage {
		GifImageDesc ImageDesc;
		GifByteType *RasterBits;
		int ExtensionBlockCount;
		ExtensionBlock *ExtensionBlocks;
	} SavedImage;
	typedef struct GifFileType {
		GifWord SWidth, SHeight;
		GifWord SColorResolution;
		GifWord SBackGroundColor;
		GifByteType AspectByte;
		ColorMapObject *SColorMap;
		int ImageCount;
		GifImageDesc Image;
		SavedImage *SavedImages;
		int ExtensionBlockCount;
		ExtensionBlock *ExtensionBlocks;
		int Error;
		void *UserData;
		void *Private;
	} GifFileType;
	typedef int (*GifInputFunc) (GifFileType *, GifByteType *, int);
	typedef int (*GifOutputFunc) (GifFileType *, const GifByteType *, int);
	typedef struct GraphicsControlBlock {
		int DisposalMode;
		_Bool UserInputFlag;
		int DelayTime;
		int TransparentColor;
	} GraphicsControlBlock;
	GifFileType *DGifOpenFileName(const char *GifFileName, int *Error);
	int DGifSlurp(GifFileType * GifFile);
	GifFileType *DGifOpen(void *userPtr, GifInputFunc readFunc, int *Error);
	int DGifCloseFile(GifFileType * GifFile);
	char *GifErrorString(int ErrorCode);
	int DGifSavedExtensionToGCB(GifFileType *GifFile, int ImageIndex, GraphicsControlBlock *GCB);
]]

-- https://luapower.com/giflib
class LIBGIF

	new: (@filename = filename) =>

	read: =>
		open = (err) -> GIF.DGifOpenFileName @filename, err

		err = ffi.new "int[1]"
		@file = open(err) or nil

		unless @file
			error ffi.string GIF.GifErrorString err[0]

		return @

	close: => ffi.C.free(@file) if GIF.DGifCloseFile(@file) == 0

	decode: (transparent = true) =>
		@read!

		check = ->
			res = GIF.DGifSlurp @file
			if res != 0
				return
			error ffi.string GIF.GifErrorString @file.Error

		check!
		@frames = {}
		@width = @file.SWidth
		@height = @file.SHeight

		gcb = ffi.new "GraphicsControlBlock"
		for i = 0, @file.ImageCount - 1
			si = @file.SavedImages[i]

			local delayMs, tColorK
			if GIF.DGifSavedExtensionToGCB(@file, i, gcb) == 1
				delayMs = gcb.DelayTime * 10
				tColorK = gcb.TransparentColor

			width, height = si.ImageDesc.Width, si.ImageDesc.Height
			colorMap = si.ImageDesc.ColorMap != nil and si.ImageDesc.ColorMap or @file.SColorMap

			length = width * height
			data = ffi.new "color_RGBA[?]", length
			for j = 0, length - 1
				k = si.RasterBits[j]
				assert k < colorMap.ColorCount

				with data[j]
					if k == tColorK and transparent
						.b = 0
						.g = 0
						.r = 0
						.a = 0
					else
						.b = colorMap.Colors[k].Blue
						.g = colorMap.Colors[k].Green
						.r = colorMap.Colors[k].Red
						.a = 0xff

			table.insert @frames, {:data, :width, :height, :delayMs, x: si.ImageDesc.Left, y: si.ImageDesc.Top, getData: => data}

		@close!

		return @

{:LIBGIF}