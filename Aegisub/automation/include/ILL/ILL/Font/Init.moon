class Init

	new: (data) =>
		{
			fontname:  @family
			bold:      @bold
			italic:    @italic
			underline: @underline
			strikeout: @strikeout
			fontsize:  @size
			scale_x:   @xscale
			scale_y:   @yscale
			spacing:   @hspace
		} = data

		-- limits the font size to 250
		if @size > 250
			factor = (@size - 100) / 100
			@xscale += @xscale * factor
			@yscale += @yscale * factor
			@size = 100

		-- Reescale x and y
		@xscale /= 100
		@yscale /= 100

		@init!

{:Init}