-- SCRIPT PROPERTIES
script_name = "Bidirectional Snapping"
script_description = "Snap to close keyframes during timing."
script_author = "PhosCity"
script_version = "1.0.3"
script_namespace = "phos.snap"

local haveDepCtrl, DependencyControl, depRec = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
	depRec = DependencyControl({
		feed = "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
	})
end

-- HELPER FUNCTIONS
local function get_frame(time)
	return aegisub.frame_from_ms(time)
end

local function get_time(frame)
	return aegisub.ms_from_frame(frame)
end

-- MAIN FUNCTIONS
local function snap_start(subs, sel)
	local keyframes = aegisub.keyframes()
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			local start_new = nil
			local start_kf = get_frame(line.start_time)
			local end_kf = get_frame(line.end_time)
			for k, kf in ipairs(keyframes) do
				if kf < start_kf then
					start_new = kf
				elseif kf == start_kf and keyframes[k + 1] < end_kf then
					start_new = keyframes[k + 1]
				end
			end
			line.start_time = get_time(start_new)
			subs[i] = line
		end
	end
end

local function snap_end(subs, sel)
	local keyframes = aegisub.keyframes()
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			local line = subs[i]
			local end_new = nil
			local start_kf = get_frame(line.start_time)
			local end_kf = get_frame(line.end_time)
			for k, kf in ipairs(keyframes) do
				if kf > end_kf and end_new == nil then
					end_new = kf
				elseif kf == end_kf and keyframes[k - 1] > start_kf then
					end_new = keyframes[k - 1]
				end
			end
			line.end_time = get_time(end_new)
			subs[i] = line
		end
	end
end

local function snap_both(subs, sel)
	snap_start(subs, sel)
	snap_end(subs, sel)
end

--Register macro
if haveDepCtrl then
	depRec:registerMacros({
		{ "Snap both", "Snap both to keyframes", snap_both },
		{ "Snap start", "Snap start to keyframes", snap_start },
		{ "Snap end", "Snap end to keyframes", snap_end },
	})
else
	aegisub.register_macro(
		script_author .. "/" .. script_name .. "/Snap both to keyframes",
		script_description,
		snap_both
	)
	aegisub.register_macro(
		script_author .. "/" .. script_name .. "/Snap start to keyframe",
		script_description,
		snap_start
	)
	aegisub.register_macro(script_author .. "/" .. script_name .. "/Snap end to keyframe", script_description, snap_end)
end
