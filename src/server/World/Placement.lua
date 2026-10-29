-- Deterministic layout maths: seeded RNG, curved path sampling, authored clearings,
-- analytic terrain height (so props never float) and a cheap spatial hash that keeps
-- trees and rocks from overlapping each other.

local WorldPlan = require(script.Parent.WorldPlan)

local Placement = {}

local CELL = 26

local occupied: { [string]: { { number } } } = {}
local pathSegments: { { a: Vector3, b: Vector3, width: number } } = {}
local mounds: { { x: number, z: number, r: number, base: number, h: number, material: Enum.Material } } = {}
local ready = false

-- ------------------------------------------------------------------------ random

local function newRng(seed: number)
	local state = math.floor(math.abs(seed)) % 4294967295
	if state < 1 then
		state = 2463534242
	end
	return function(min: number?, max: number?): number
		state = bit32.bxor(state, bit32.lshift(state, 13))
		state = bit32.bxor(state, bit32.rshift(state, 17))
		state = bit32.bxor(state, bit32.lshift(state, 5))
		state = state % 4294967295
		local unit = state / 4294967295
		if min and max then
			return min + (max - min) * unit
		end
		return unit
	end
end

function Placement.rng(seed: number)
	return newRng(seed)
end

function Placement.range(rng, min: number, max: number): number
	return rng(min, max)
end

function Placement.int(rng, min: number, max: number): number
	return math.floor(rng(min, max + 0.999))
end

function Placement.pick(rng, list: { any }): any
	return list[math.clamp(math.floor(rng() * #list) + 1, 1, #list)]
end

function Placement.weighted(rng, weights: { any }): string
	local total = 0
	for _, entry in weights do
		total += entry[2]
	end
	local roll = rng() * total
	for _, entry in weights do
		roll -= entry[2]
		if roll <= 0 then
			return entry[1]
		end
	end
	return weights[#weights][1]
end

-- ------------------------------------------------------------------------- paths

local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2 = t * t
	local t3 = t2 * t
	local function axis(a: number, b: number, c: number, d: number): number
		return 0.5
			* (
				2 * b
				+ (-a + c) * t
				+ (2 * a - 5 * b + 4 * c - d) * t2
				+ (-a + 3 * b - 3 * c + d) * t3
			)
	end
	return Vector3.new(axis(p0.X, p1.X, p2.X, p3.X), 0, axis(p0.Z, p1.Z, p2.Z, p3.Z))
end

local function samplePath(points: { Vector3 }, step: number): { Vector3 }
	local out = {}
	for i = 1, #points - 1 do
		local p0 = points[math.max(1, i - 1)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[math.min(#points, i + 2)]
		local length = (p2 - p1).Magnitude
		local steps = math.max(2, math.ceil(length / step))
		for s = 1, steps do
			table.insert(out, catmull(p0, p1, p2, p3, s / steps))
		end
	end
	return out
end

local function distanceToSegment(x: number, z: number, a: Vector3, b: Vector3): number
	local dx, dz = b.X - a.X, b.Z - a.Z
	local lenSq = dx * dx + dz * dz
	if lenSq < 0.0001 then
		return math.sqrt((x - a.X) ^ 2 + (z - a.Z) ^ 2)
	end
	local t = ((x - a.X) * dx + (z - a.Z) * dz) / lenSq
	t = math.clamp(t, 0, 1)
	local px, pz = a.X + dx * t, a.Z + dz * t
	return math.sqrt((x - px) ^ 2 + (z - pz) ^ 2)
end

function Placement.distanceToPaths(x: number, z: number): number
	local best = math.huge
	for _, seg in pathSegments do
		local d = distanceToSegment(x, z, seg.a, seg.b)
		if d < best then
			best = d
		end
	end
	return best
end

function Placement.pathWidthAt(x: number, z: number): number
	local best, width = math.huge, 12
	for _, seg in pathSegments do
		local d = distanceToSegment(x, z, seg.a, seg.b)
		if d < best then
			best = d
			width = seg.width
		end
	end
	return width
end

function Placement.pathSamples(points: { Vector3 }, step: number): { Vector3 }
	return samplePath(points, step)
end

-- -------------------------------------------------------------------- clearings

function Placement.inClearing(x: number, z: number, extra: number?): boolean
	local pad = extra or 0
	for _, c in WorldPlan.clearings do
		local dx, dz = x - c.center.X, z - c.center.Z
		local reach = c.radius + pad
		if dx * dx + dz * dz < reach * reach then
			return true
		end
	end
	return false
end

-- ------------------------------------------------------------------------ water

-- Farm glades: the harvest clusters are kept open so entities are easy to find and
-- always have room to spawn.
function Placement.inFarm(x: number, z: number, extra: number?): boolean
	local pad = extra or 0
	for _, clusters in WorldPlan.zones do
		for _, spec in clusters do
			local dx, dz = x - spec.center.X, z - spec.center.Z
			local reach = spec.radius + 14 + pad
			if dx * dx + dz * dz < reach * reach then
				return true
			end
		end
	end
	return false
end

function Placement.inWater(x: number, z: number, extra: number?): boolean
	local pad = extra or 0
	for _, lake in WorldPlan.lakes do
		local dx, dz = x - lake.center.X, z - lake.center.Z
		local reach = lake.radius + pad
		if dx * dx + dz * dz < reach * reach then
			return true
		end
	end
	for _, stream in WorldPlan.streams do
		local pts = stream.points
		for i = 1, #pts - 1 do
			if distanceToSegment(x, z, pts[i], pts[i + 1]) < stream.width * 0.5 + pad then
				return true
			end
		end
	end
	return false
end

-- ----------------------------------------------------------------------- mounds

local function moundMaterial(x: number, z: number): Enum.Material
	if (x + 430) ^ 2 + (z - 430) ^ 2 < 330 ^ 2 then
		return Enum.Material.Mud
	end
	if x > 330 and z < -160 then
		return Enum.Material.Rock
	end
	return Enum.Material.Grass
end

local function buildMounds()
	mounds = {}
	local rng = newRng(WorldPlan.SEED + 77)
	local limit = WorldPlan.TERRAIN_RADIUS - 180
	for gx = -limit, limit, 118 do
		for gz = -limit, limit, 118 do
			local x = gx + rng(-44, 44)
			local z = gz + rng(-44, 44)
			local r = rng(52, 96)
			local h = rng(6, 26)
			local dist = math.sqrt(x * x + z * z)
			if dist + r < limit then
				local blocked = Placement.inClearing(x, z, r * 0.55)
					or Placement.inWater(x, z, r * 0.7 + 18)
					or Placement.distanceToPaths(x, z) < Placement.pathWidthAt(x, z) * 0.5 + r * 0.6
				-- Keep the plaza, the glade and the boss arena perfectly flat.
				if not blocked and (x * x + z * z) < 150 * 150 then
					blocked = true
				end
				if not blocked then
					table.insert(mounds, {
						x = x,
						z = z,
						r = r,
						h = h,
						base = h - r,
						material = moundMaterial(x, z),
					})
				end
			end
		end
	end
end

function Placement.mounds()
	return mounds
end

-- Analytic surface height of the generated terrain. Roblox voxelises the surface,
-- so callers sink props by ~1 stud to guarantee nothing floats.
function Placement.heightAt(x: number, z: number): number
	local best = 0
	for i = 1, #mounds do
		local m = mounds[i]
		local dx, dz = x - m.x, z - m.z
		local d2 = dx * dx + dz * dz
		if d2 < m.r * m.r then
			local y = m.base + math.sqrt(m.r * m.r - d2)
			if y > best then
				best = y
			end
		end
	end
	return best
end

-- ------------------------------------------------------------------- occupancy

function Placement.isFree(x: number, z: number, radius: number): boolean
	local minX, maxX = math.floor((x - radius) / CELL), math.floor((x + radius) / CELL)
	local minZ, maxZ = math.floor((z - radius) / CELL), math.floor((z + radius) / CELL)
	for gx = minX, maxX do
		for gz = minZ, maxZ do
			local bucket = occupied[gx .. ":" .. gz]
			if bucket then
				for _, c in bucket do
					local dx, dz = x - c[1], z - c[2]
					local reach = radius + c[3]
					if dx * dx + dz * dz < reach * reach then
						return false
					end
				end
			end
		end
	end
	return true
end

function Placement.reserve(x: number, z: number, radius: number)
	local key = math.floor(x / CELL) .. ":" .. math.floor(z / CELL)
	local bucket = occupied[key]
	if not bucket then
		bucket = {}
		occupied[key] = bucket
	end
	table.insert(bucket, { x, z, radius })
end

-- Jittered grid scatter inside a disc. `place` returns true when it actually placed
-- something (so the part budget can be honoured).
function Placement.scatterDisc(
	center: Vector3,
	radius: number,
	spacing: number,
	density: number,
	rng,
	place: (number, number) -> boolean,
	limit: number?
): number
	local placed = 0
	local cap = limit or math.huge
	local steps = math.ceil(radius / spacing)
	for ix = -steps, steps do
		for iz = -steps, steps do
			if placed >= cap then
				return placed
			end
			local jx = (ix + rng(-0.45, 0.45)) * spacing
			local jz = (iz + rng(-0.45, 0.45)) * spacing
			if jx * jx + jz * jz <= radius * radius and rng() <= density then
				if place(center.X + jx, center.Z + jz) then
					placed += 1
				end
			end
		end
	end
	return placed
end

function Placement.init()
	if ready then
		return
	end
	ready = true
	occupied = {}
	pathSegments = {}
	for _, path in WorldPlan.paths do
		local samples = samplePath(path.points, 12)
		for i = 1, #samples - 1 do
			table.insert(pathSegments, { a = samples[i], b = samples[i + 1], width = path.width })
		end
	end
	buildMounds()
end

return Placement
