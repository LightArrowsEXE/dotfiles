module_version = "1.4.0"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, ffi, requireffi
if haveDepCtrl
	depctrl = DependencyControl {
		name: "clipper2"
		version: module_version
		description: "A polygon clipping and offsetting library"
		author: "ILLTeam"
		moduleName: "clipper2.clipper2"
		url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts"
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
		{
			{"ffi"}
			{
				"requireffi.requireffi"
				version: "0.1.2"
				url: "https://github.com/TypesettingTools/ffi-experiments"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ffi-experiments/master/DependencyControl.json"
			}
		}
	}
	ffi, requireffi = depctrl\requireModules!
else
	ffi = require "ffi"
	requireffi = require "requireffi.requireffi"

import C, cdef, gc, metatype from ffi
pc = requireffi "clipper2.clipper2.clipper2"

cdef [[
	const char *version();
	const char *errVal();
	void setPrecision(int newPrecision);

	typedef struct {double x, y;} PointD;
	typedef struct PathD PathD;
	typedef struct PathsD PathsD;

	// Path
	PathD *NewPath();
	void PathFree(PathD *path);
	bool PathAddPoint(PathD *path, double x, double y);
	int PathLen(PathD *path);
	PointD *PathGet(PathD *path, int i);
	void PathSet(PathD *path, int i, double x, double y);
	PathD *PathMove(PathD *path, double dx, double dy);
	bool PathFlattenLine(PathD *path, int reduce, double x1, double y1, double x2, double y2);
	bool PathFlattenBezier(PathD *path, int reduce, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4);
	PathD *PathFlatten(PathD *path, int reduce);

	// Paths
	PathsD *NewPaths();
	void PathsFree(PathsD *paths);
	bool PathsAdd(PathsD *paths, PathD *path);
	int PathsLen(PathsD *paths);
	PathD *PathsGet(PathsD *paths, int i);
	void PathsSet(PathsD *paths, int i, PathD *path);
	PathsD *PathsMove(PathsD *paths, double dx, double dy);
	PathsD *PathsFlatten(PathsD *paths, int reduce);
	PathsD *PathsInflate(PathsD *paths, double delta, int jt, int et, double mt, double at);
	PathsD *PathsIntersect(PathsD *sbj, PathsD *clp, int fr);
	PathsD *PathsUnion(PathsD *sbj, PathsD *clp, int fr);
	PathsD *PathsDifference(PathsD *sbj, PathsD *clp, int fr);
	PathsD *PathsXor(PathsD *sbj, PathsD *clp, int fr);
]]

Enums = {
	FillRule: {even_odd: 0, non_zero: 1, positive: 2, negative: 3}
	JoinType: {square: 0, round: 1, miter: 2}
	EndType:  {polygon: 0, joined: 1, butt: 2, square: 3, round: 4}
}

SetEnum = (enumName, n) ->
	if type(n) == "string"
		n = Enums[enumName][n]
		assert n, "#{enumName} undefined"
	return n

-- lib
CPP = {
	path: {}
	paths: {}
	version: module_version
	ffiversion: -> ffi.string pc.version!
	viewError: -> ffi.string pc.errVal!
	setPrecision: (n = 3) -> pc.setPrecision n
}

-- Path
CPP.path.new = -> gc pc.NewPath!, pc.PathFree
CPP.path.add = (mode = "line", ...) =>
	points = {...}
	if mode == "line" and #points == 2
		assert pc.PathAddPoint(@, ...), CPP.viewError!
	elseif mode == "line" and #points == 5
		assert pc.PathFlattenLine(@, ...), CPP.viewError!
	elseif mode == "bezier" and #points == 9
		assert pc.PathFlattenBezier(@, ...), CPP.viewError!
CPP.path.len = => pc.PathLen @
CPP.path.get = (i = 1) => pc.PathGet @, i < 1 and 0 or i - 1
CPP.path.set = (i = 1, x, y) => pc.PathSet @, i < 1 and 0 or i - 1, x, y
CPP.path.move = (x, y) => gc pc.PathMove(@, x, y), pc.PathFree
CPP.path.flatten = (reduce = 2) => gc pc.PathFlatten(@, reduce), pc.PathFree
CPP.path.push = (...) =>
	-- \push {x: 0, y: 0}, Point()
	for {:x, :y} in *{...}
		@add "line", x, y
CPP.path.map = (fn) =>
	for i = 1, @len!
		p = @get i
		x, y = fn p.x, p.y
		if x and y
			@set i, x, y

-- Paths
CPP.paths.new = -> gc pc.NewPaths!, pc.PathsFree
CPP.paths.add = (path) => assert pc.PathsAdd(@, path), CPP.viewError!
CPP.paths.len = => pc.PathsLen @
CPP.paths.get = (i = 1) => pc.PathsGet @, i < 1 and 0 or i - 1
CPP.paths.set = (i = 1, path) => pc.PathsSet @, i < 1 and 0 or i - 1, path
CPP.paths.move = (x, y) => gc pc.PathsMove(@, x, y), pc.PathsFree
CPP.paths.flatten = (reduce = 2) => gc pc.PathsFlatten(@, reduce), pc.PathsFree
CPP.paths.push = (...) =>
	-- \push Path!, Path!
	for path in *{...}
		@add path
CPP.paths.map = (fn) =>
	for i = 1, @len!
		@get(i)\map fn

CPP.paths.inflate = (delta, jt = 0, et = 0, mt = 2, at = 0) =>
	jt = SetEnum "JoinType", jt
	et = SetEnum "EndType", et
	solution = pc.PathsInflate @, delta, jt, et, mt, at
	assert solution != nil, CPP.viewError!
	return gc solution, pc.PathsFree

CPP.paths.intersection = (paths, fr = 1) =>
	fr = SetEnum "FillRule", fr
	solution = pc.PathsIntersect @, paths, fr
	assert solution != nil, CPP.viewError!
	return gc solution, pc.PathsFree

CPP.paths.union = (paths, fr = 1) =>
	fr = SetEnum "FillRule", fr
	solution = pc.PathsUnion @, paths, fr
	assert solution != nil, CPP.viewError!
	return gc solution, pc.PathsFree

CPP.paths.difference = (paths, fr = 1) =>
	fr = SetEnum "FillRule", fr
	solution = pc.PathsDifference @, paths, fr
	assert solution != nil, CPP.viewError!
	return gc solution, pc.PathsFree

CPP.paths.xor = (paths, fr = 1) =>
	fr = SetEnum "FillRule", fr
	solution = pc.PathsXor @, paths, fr
	assert solution != nil, CPP.viewError!
	return gc solution, pc.PathsFree

metatype "PathD",  {__index: CPP.path}
metatype "PathsD", {__index: CPP.paths}

if haveDepCtrl
	depctrl\register CPP
else
	CPP