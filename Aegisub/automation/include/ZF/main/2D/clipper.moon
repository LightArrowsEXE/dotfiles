import CPP, has_loaded, version from require "zpolyclipping.polyclipping"

import POINT   from require "ZF.main.2D.point"
import SEGMENT from require "ZF.main.2D.segment"
import PATH    from require "ZF.main.2D.path"
import SHAPE   from require "ZF.main.2D.shape"

class CLIPPER

    version: "1.0.3"

    -- @param subj string || SHAPE
    -- @param clip string || SHAPE
    -- @param close boolean
    -- @param scale number
    new: (subj, clip, close = false) =>
        unless has_loaded
            libError "libpolyclipping"

        assert subj, "subject expected"
        subj = SHAPE(subj, close)\flatten nil, nil, 1, "b"
        clip = clip and SHAPE(clip, close)\flatten(nil, nil, 1, "b") or nil
        scale = CPP.SCALE_POINT_SIZE

        createPaths = (paths) ->
            createPath = (path) ->
                newPath = CPP.path.new!
                if path[1]
                    {a, b} = path[1]["segment"]
                    newPath\add a.x * scale, a.y * scale
                    newPath\add b.x * scale, b.y * scale
                for i = 2, #path
                    c = path[i]["segment"][2]
                    newPath\add c.x * scale, c.y * scale
                return newPath
            newPaths = CPP.paths.new!
            for p in *paths
                newPaths\add createPath p.path
            return newPaths

        @cls = close
        @sbj = createPaths subj.paths
        @clp = clip and createPaths(clip.paths) or nil

    -- removes useless vertices from a shape
    -- @return CLIPPER
    simplify: (ft) =>
        @sbj = @sbj\simplify ft
        return @

    -- creates a run for the clipper
    -- @param fr string
    -- @param ct string
    -- @return CLIPPER
    clipper: (ct = "intersection", ft = "even_odd") =>
        assert @clp, "expected clip"
        c = CPP.clipper.new!
        c\add_paths @sbj, "subject"
        c\add_paths @clp, "clip"
        @sbj = c\execute ct, ft
        return @

    -- creates a run for clipper offset
    -- @param size number
    -- @param jt string
    -- @param et string
    -- @param mtl number
    -- @param act number
    -- @return CLIPPER
    offset: (size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25) =>
        jt = jt\lower!
        o = CPP.offset.new mtl, act
        @sbj = o\paths @sbj, size, jt, et
        return @

    -- generates a stroke around the shape
    -- @param size number
    -- @param jt string
    -- @param mode string
    -- @param mtl number
    -- @param act number
    -- @return CLIPPER, CLIPPER
    toStroke: (size, jt = "round", mode = "center", mtl, act) =>
        assert size >= 0, "The size must be positive"

        mode = mode\lower!
        size = mode == "inside" and -size or size
        fill = CLIPPER (mode != "center" and @simplify! or @)\build!
        offs = CLIPPER @offset(size, jt, mode == "center" and "closed_line" or nil, mtl, act)\build!

        switch mode
            when "outside"
                @sbj = offs.sbj
                @clp = fill.sbj
                @clip(true), fill
            when "inside"
                @sbj = fill.sbj
                @clp = offs.sbj
                @clip(true), offs
            when "center"
                @sbj = fill.sbj
                @clp = offs.sbj
                offs, @clip(true)

    -- cuts a shape through the \clip - \iclip tags
    -- @param iclip boolean
    -- @return CLIPPER
    clip: (iclip) => iclip and @clipper("difference") or @clipper "intersection"

    -- builds the shape
    -- @param simplifyType string
    -- @param precision integer
    -- @param decs integer
    -- @return string
    build: (simplifyType, precision = 1, decs = 3) =>
        new, rsc = SHAPE!, CPP.RESCALE_POINT_SIZE
        for i = 1, @sbj\len!
            path = @sbj\get i
            new.paths[i] = PATH!
            for j = 2, path\len!
                prevPoint = path\get j - 1
                currPoint = path\get j - 0
                p, c = POINT!, POINT!
                p.x = tonumber(prevPoint.X) * rsc
                p.y = tonumber(prevPoint.Y) * rsc
                c.x = tonumber(currPoint.X) * rsc
                c.y = tonumber(currPoint.Y) * rsc
                new.paths[i]\push SEGMENT p, c
            if simplifyType
                new.paths[i] = new.paths[i]\simplify simplifyType, precision, precision * 3
        return new\build decs

{:CLIPPER}