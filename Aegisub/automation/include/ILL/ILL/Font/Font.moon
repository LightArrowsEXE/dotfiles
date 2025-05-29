-- Copyright (c) 2014, Christoph "Youka" Spanknebel

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- Font scale values for increased size & later downscaling to produce floating point coordinates
export FONT_LF_FACESIZE = 32
export FONT_UPSCALE = 64
export FONT_DOWNSCALE = 1 / FONT_UPSCALE
export IS_UNIX = jit.os != "Windows"

unless IS_UNIX
	-- if the operating system is windows
	import WindowsGDI from require "ILL.ILL.Font.Win"
	return {Font: WindowsGDI}

-- if the operating system is unix
import FreeType from require "ILL.ILL.Font.Unx"
return {Font: FreeType}