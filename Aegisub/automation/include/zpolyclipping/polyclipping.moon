versionRecord = "6.4.2"

haveDepCtrl, DependencyControl = pcall require, 'l0.DependencyControl'

local ffi, requireffi, depctrl
if haveDepCtrl
    depctrl = DependencyControl({
        name: "clipper"
        version: versionRecord
        description: "Polygon Clipping and Offsetting"
        author: "Zeref"
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        moduleName: "zpolyclipping.polyclipping"
        feed: "https://raw.githubusercontent.com/TypesettingTools/zeref-Aegisub-Scripts/main/DependencyControl.json"
        {
            { "ffi" }
            { "requireffi.requireffi", version: "0.1.2" }
        }
    })
    ffi, requireffi = depctrl\requireModules!
else
    ffi = require "ffi"
    requireffi = require "requireffi.requireffi"

import C, cdef, gc, metatype from ffi
has_loaded, pc = pcall requireffi, "zpolyclipping.polyclipping.polyclipping"

cdef [[
    typedef struct Path Path;
    typedef struct Paths Paths;
    typedef struct ClipperOffset ClipperOffset;
    typedef struct Clipper Clipper;
    typedef signed long long cInt;
    typedef struct {cInt X, Y;} IntPoint;
    typedef enum {
        ctIntersection = 0,
        ctUnion = 1,
        ctDifference = 2,
        ctXor = 3
    } ClipType;
    typedef enum {
        ptSubject = 0,
        ptClip = 1
    } PolyType;
    typedef enum {
        pftEvenOdd = 0,
        pftNonZero = 1,
        pftPositive = 2,
        pftNegative = 3
    } PolyFillType;
    typedef enum {
        ioReverseSolution = 1,
        ioStrictlySimple = 2,
        ioPreserveCollinear = 4
    } InitOptions;
    typedef enum {
        jtSquare = 0,
        jtRound = 1,
        jtMiter = 2
    } JoinType;
    typedef enum {
        etClosedPolygon = 0,
        etClosedLine = 1,
        etOpenButt = 2,
        etOpenSquare = 3,
        etOpenRound = 4
    } EndType;
    const char error_val();
    // Section Path
    Path* path_new();
    void path_free(Path *self);
    IntPoint* path_get(Path *self, int i);
    bool path_add(Path *self, cInt x, cInt y);
    int path_size(Path *self);
    bool path_orientation(Path *self);
    double path_area(Path *self);
    void path_reverse(Path *self);
    int path_point_in_polygon(Path *self, cInt x, cInt y);
    Paths* path_simplify(Path *self, int fillType);
    Path* path_clean_polygon(Path *self, double distance);
    // Section Paths
    Paths* paths_new();
    void paths_free(Paths *self);
    Path* paths_get(Paths *self, int i);
    bool paths_add(Paths *self, Path *path);
    int paths_size(Paths *self);
    void paths_reverse(Paths *self);
    Paths* paths_simplify(Paths *self, int fillType);
    Paths* paths_clean_polygon(Paths *self, double distance);
    // Section ClipperOffset
    ClipperOffset* offset_new(double miterLimit, double roundPrecision);
    void offset_free(ClipperOffset *self);
    Paths* offset_path(ClipperOffset *self, Path *subj, double delta, int joinType, int endType);
    Paths* offset_paths(ClipperOffset *self, Paths *subj, double delta, int joinType, int endType);
    void offset_clear(ClipperOffset *self);
    // Section Clipper
    Clipper* clipper_new(int initOptions);
    void clipper_free(Clipper *self);
    void clipper_clear(Clipper *self);
    void clipper_reverse_solution(Clipper *self, bool value);
    void clipper_preserve_collinear(Clipper *self, bool value);
    void clipper_strictly_simple(Clipper *self, bool value);
    bool clipper_add_path(Clipper *self, Path *paths, int polyType, bool closed);
    bool clipper_add_paths(Clipper *self, Paths *paths, int polyType, bool closed);
    Paths* clipper_execute(Clipper *self, int clipType, int subjFillType, int clipFillType);
]]

-- Polyclipping
CPP = {path: {}, paths: {}, offset: {}, clipper: {}}

CPP.SCALE_POINT_SIZE = 1000
CPP.RESCALE_POINT_SIZE = 1 / CPP.SCALE_POINT_SIZE

CPP.ClipType = {
    intersection: C.ctIntersection,
    union: C.ctUnion,
    difference: C.ctDifference,
    xor: C.ctXor
}

CPP.PolyType = {
    subject: C.ptSubject,
    clip: C.ptClip
}

CPP.PolyFillType = {
    even_odd: C.pftEvenOdd,
    non_zero: C.pftNonZero,
    positive: C.pftPositive,
    negative: C.pftNegative
}

CPP.InitOptions = {
    reverse_solution: C.ioReverseSolution,
    strictly_simple: C.ioStrictlySimple,
    preserve_collinear: C.ioPreserveCollinear
}

CPP.JoinType = {
    square: C.jtSquare,
    round: C.jtRound,
    miter: C.jtMiter
}

CPP.EndType = {
    closed_polygon: C.etClosedPolygon,
    closed_line: C.etClosedLine,
    open_butt: C.etOpenButt,
    open_square: C.etOpenSquare,
    open_round: C.etOpenRound
}

-- gets error
CPP.error = -> error ffi.string pc.error_val!

-- CLASS Path
CPP.path.new = -> gc pc.path_new!, pc.path_free
CPP.path.get = (@, i = 1) -> pc.path_get @, (i < 1 and 1 or i) - 1
CPP.path.add = (@, x, y) -> assert pc.path_add(@, x, y), "out of memory"
CPP.path.len = (@) -> pc.path_size @
CPP.path.orientation = (@) -> pc.path_orientation @
CPP.path.area = (@) -> pc.path_area @
CPP.path.reverse = (@) -> pc.path_reverse @
CPP.path.simplify = (@, fillType = "non_zero") -> gc pc.path_simplify(@, CPP.PolyFillType[fillType]), pc.paths_free
CPP.path.point_in_polygon = (@, x, y) -> pc.path_point_in_polygon(@, x, y) == 1
CPP.path.clean = (@, distance) -> gc pc.path_clean_polygon(@, distance), pc.path_free

-- CLASS Paths
CPP.paths.new = -> gc pc.paths_new!, pc.paths_free
CPP.paths.get = (@, i = 1) -> pc.paths_get @, (i < 1 and 1 or i) - 1
CPP.paths.add = (@, path) -> assert pc.paths_add(@, path), "out of memory"
CPP.paths.len = (@) -> pc.paths_size @
CPP.paths.reverse = (@) -> pc.paths_reverse @
CPP.paths.simplify = (@, fillType = "non_zero") -> gc pc.paths_simplify(@, CPP.PolyFillType[fillType]), pc.paths_free
CPP.paths.clean = (@, distance) -> gc pc.paths_clean_polygon(@, distance), pc.paths_free

-- CLASS ClipperOffset
CPP.offset.new = (miterLimit = 2, roundPrecision = 0.25) -> gc pc.offset_new(miterLimit, roundPrecision), pc.offset_free
CPP.offset.clear = (@) -> pc.offset_clear @
CPP.offset.path = (@, path, delta, joinType = "round", endType = "closed_polygon") ->
    result = pc.offset_path @, path, delta * CPP.SCALE_POINT_SIZE, CPP.JoinType[joinType], CPP.EndType[endType]
    if result == nil
        CPP.error!
    return gc result, pc.paths_free
CPP.offset.paths = (@, paths, delta, joinType = "round", endType = "closed_polygon") ->
    result = pc.offset_paths @, paths, delta * CPP.SCALE_POINT_SIZE, CPP.JoinType[joinType], CPP.EndType[endType]
    if result == nil
        CPP.error!
    return gc result, pc.paths_free

-- CLASS Clipper
CPP.clipper.new = (initOptions = "strictly_simple") -> gc pc.clipper_new(CPP.InitOptions[initOptions]), pc.clipper_free
CPP.clipper.clear = (@) -> pc.clipper_clear @
CPP.clipper.reverse_solution = (@, value = false) -> pc.clipper_reverse_solution @, value
CPP.clipper.preserve_collinear = (@, value = false) -> pc.preserve_collinear @, value
CPP.clipper.strictly_simple = (@, value = false) -> pc.strictly_simple @, value
CPP.clipper.add_path = (@, path, polyType = "subject", closed = true) ->
    unless pc.clipper_add_path @, path, CPP.PolyType[polyType], closed
        CPP.error!
CPP.clipper.add_paths = (@, paths, polyType = "subject", closed = true) ->
    unless pc.clipper_add_paths @, paths, CPP.PolyType[polyType], closed
        CPP.error!
CPP.clipper.execute = (@, clipType = "union", subjFillType = "non_zero", clipFillType = "non_zero") ->
    result = pc.clipper_execute @, CPP.ClipType[clipType], CPP.PolyFillType[subjFillType], CPP.PolyFillType[clipFillType]
    if result == nil
        CPP.error!
    return gc result, pc.paths_free

metatype "Path",          {__index: CPP.path}
metatype "Paths",         {__index: CPP.paths}
metatype "ClipperOffset", {__index: CPP.offset}
metatype "Clipper",       {__index: CPP.clipper}


if haveDepCtrl
	return depctrl\register {:CPP, :has_loaded, version: versionRecord}
else
	return {:CPP, :has_loaded, version: versionRecord}
