import abs, acos, cos, floor, max, min, random, randomseed, sqrt, pi from math

randomseed os.time! * 1e6

class Math

	-- returns the sign of the number
	sign: (a) -> a > 0 and 1 or a < 0 and -1 or 0

	-- limits the value of a between b and c
	clamp: (a, b, c) -> min max(a, b), c

	-- rounds the number according to the number of decimal places
	round: (a, dec = 3) ->
		t = 10 ^ floor dec
		a = floor a * t + 0.5
		b = floor a + 0.5
		return dec >= 1 and a / t or b

	-- linear interpolation in the range of 0 and 1
	lerp: (t, a, b) ->
		t = Math.clamp t, 0, 1
		return (1 - t) * a + t * b 

	-- returns a random number in the range of b and c
	random: (a, b) ->
		return random! * (b - a) + a

	-- generates natural random patterns
	-- https://gist.github.com/nowl/828013?permalink_comment_id=2807232#gistcomment-2807232
	perlinNoise: (x, y, freq, depth, seed = 2000) ->
		perlinHash = {
			208, 34, 231, 213, 32, 248, 233, 56, 161, 78, 24, 140, 71, 48, 140, 254, 245, 255
			247, 247, 40, 185, 248, 251, 245, 28, 124, 204, 204, 76, 36, 1, 107, 28, 234, 163
			202, 224, 245, 128, 167, 204, 9, 92, 217, 54, 239, 174, 173, 102, 193, 189, 190, 121
			100, 108, 167, 44, 43, 77, 180, 204, 8, 81, 70, 223, 11, 38, 24, 254, 210, 210, 177
			32, 81, 195, 243, 125, 8, 169, 112, 32, 97, 53, 195, 13, 203, 9, 47, 104, 125, 117
			114, 124, 165, 203, 181, 235, 193, 206, 70, 180, 174, 0, 167, 181, 41, 164, 30, 116
			127, 198, 245, 146, 87, 224, 149, 206, 57, 4, 192, 210, 65, 210, 129, 240, 178, 105
			228, 108, 245, 148, 140, 40, 35, 195, 38, 58, 65, 207, 215, 253, 65, 85, 208, 76, 62
			3, 237, 55, 89, 232, 50, 217, 64, 244, 157, 199, 121, 252, 90, 17, 212, 203, 149, 152
			140, 187, 234, 177, 73, 174, 193, 100, 192, 143, 97, 53, 145, 135, 19, 103, 13, 90
			135, 151, 199, 91, 239, 247, 33, 39, 145, 101, 120, 99, 3, 186, 86, 99, 41, 237, 203
			111, 79, 220, 135, 158, 42, 30, 154, 120, 67, 87, 167, 135, 176, 183, 191, 253, 115
			184, 21, 233, 58, 129, 233, 142, 39, 128, 211, 118, 137, 139, 255, 114, 20, 218, 113
			154, 27, 127, 246, 250, 1, 8, 198, 250, 209, 92, 222, 173, 21, 88, 102, 219
		}
		noise = (x, y) ->
			yindex = (y + seed) % 256
			yindex += yindex < 0 and 256 or 0
			xindex = (perlinHash[1 + yindex] + x) % 256
			xindex += xindex < 0 and 256 or 0
			return perlinHash[1 + xindex]
		smooth = (x, y, s) -> Math.lerp s * s * (3 - 2 * s), x, y
		noise2D = (x, y) ->
			x_int = floor x
			y_int = floor y
			x_frac = x - x_int
			y_frac = y - y_int
			s = noise x_int, y_int
			t = noise x_int + 1, y_int
			u = noise x_int, y_int + 1
			v = noise x_int + 1, y_int + 1
			low = smooth s, t, x_frac
			high = smooth u, v, x_frac
			return smooth low, high, y_frac
		xa = x * freq
		ya = y * freq
		amp, fin, div = 1, 0, 0
		for i = 0, depth - 1
			div += 256 * amp
			fin += noise2D(xa, ya) * amp
			amp /= 2
			xa *= 2
			ya *= 2
		return fin / div

	-- gets the roots of a cubic equation
	cubicRoots: (a, b, c, d, ep = 1e-8) ->
		cubeRoot = (x) ->
			y = abs(x) ^ (1 / 3)
			return x < 0 and -y or y

		p = (3 * a * c - b * b) / (3 * a * a)
		q = (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (27 * a * a * a)

		roots = {}
		if abs(p) < ep
			roots[1] = cubeRoot -q
		elseif abs(q) < ep
			roots[1] = 0
			roots[2] = p < 0 and sqrt(-p) or nil
			roots[3] = p < 0 and -sqrt(-p) or nil
		else
			D = q * q / 4 + p * p * p / 27
			if abs(D) < ep
				roots[1] = -1.5 * q / p
				roots[2] = 3 * q / p
			elseif D > 0
				u = cubeRoot -q / 2 - sqrt D
				roots[1] = u - p / (3 * u)
			else
				u = 2 * sqrt -p / 3
				t = acos(3 * q / p / u) / 3
				k = 2 * pi / 3
				roots[1] = u * cos t
				roots[2] = u * cos t - k
				roots[3] = u * cos t - 2 * k

		for i = 1, #roots
			roots[i] -= b / (3 * a)

		return roots

{:Math}