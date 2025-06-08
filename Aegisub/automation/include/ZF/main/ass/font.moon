class FONT

    version: "1.0.0"

    new: (styleref) =>
        if styleref
            with styleref
                @f = Yutils.decode.create_font .fontname, .bold, .italic, .underline, .strikeout, .fontsize, .scale_x / 100, .scale_y / 100, .spacing
        else
            error "missing style values"

    metrics: => @f.metrics!
    extents: (text) => @f.text_extents text
    shape: (text) => @f.text_to_shape(text)\gsub " c", ""

    get: (text) =>
        metrics = @metrics text
        extents = @extents text
        shape = @shape text
        return {
            :shape
            width:            tonumber extents.width
            height:           tonumber extents.height
            ascent:           tonumber metrics.ascent
            descent:          tonumber metrics.descent
            internal_leading: tonumber metrics.internal_leading
            external_leading: tonumber metrics.external_leading
        }

{:FONT}