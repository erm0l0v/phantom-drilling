class_name TetrominoData

enum ShapeType { I, O, T, S, Z, J, L }

# Each entry: 4 rotation states, each an Array of 4 Vector2i(col,row) cell
# offsets inside a local 4x4 box. States were derived by applying the
# standard 4x4-box clockwise rotation (x,y) -> (3-y,x) three times from a
# hand-picked state 0 per shape, then hand-verified cell-by-cell.
const SHAPES := {
	ShapeType.I: [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],
	],
	ShapeType.O: [
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)],
	],
	ShapeType.T: [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 1)],
		[Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 2)],
	],
	ShapeType.S: [
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 1)],
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(2, 3)],
	],
	ShapeType.Z: [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 0), Vector2i(2, 1)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 1), Vector2i(2, 2)],
	],
	ShapeType.J: [
		[Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 0)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 2)],
		[Vector2i(1, 3), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
	],
	ShapeType.L: [
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(3, 1)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
	],
}

# Key: 3x3 pattern of same-type neighbor occupancy around a cell, as
# [row][col] where row 0 = above, row 2 = below, col 0 = left, col 2 = right
# (row 1 / col 1 is the cell itself and is always 0):
#   [UL, U, UR]
#   [ L, 0,  R]
#   [DL, D, DR]
# 1 = that neighbor is the same building type, 0 = not (or not checked).
# A diagonal (UL/UR/DL/DR) is only ever non-zero when the two orthogonal
# sides forming that corner are both set and the opposite two are not (e.g.
# UL is only ever checked when U and L are set and D and R aren't) - that's
# what picks the "smooth" vs "notched" corner tile variant. See
# neighbor_pattern() below for how a pattern is built from the world.
# Value: 1-based tile index into the building tile sheets. Add/edit entries
# here directly to reassign tile numbers.
const CONNECTIVITY_TILE := {
	[
		[0, 0, 0],
	 	[0, 0, 0],
	 	[0, 0, 0]]: 1,
	[
		[0, 0, 0],
	 	[0, 0, 1],
	 	[0, 0, 0]]: 2,
	[
		[0, 0, 0],
	 	[1, 0, 1],
	 	[0, 0, 0]]: 3,
	[
		[0, 0, 0],
	 	[1, 0, 0],
	 	[0, 0, 0]]: 4,
	[
		[0, 0, 0],
	 	[0, 0, 0],
	 	[0, 1, 0]]: 5,
	[
		[0, 1, 0],
	 	[0, 0, 0],
	 	[0, 0, 0]]: 6,
	[
		[0, 1, 0],
	 	[0, 0, 0],
	 	[0, 1, 0]]: 7,
	[
		[0, 0, 0],
	 	[0, 0, 1],
	 	[0, 1, 0]]: 8,
	[
		[0, 1, 0],
	 	[1, 0, 0],
	 	[0, 0, 0]]: 9,
	[
		[0, 0, 0],
	 	[0, 0, 1],
	 	[0, 1, 1]]: 10,
	[
		[0, 0, 0],
	 	[1, 0, 1],
	 	[1, 1, 1]]: 11,
	[
		[0, 0, 0],
	 	[1, 0, 0],
	 	[1, 1, 0]]: 12,
	[
		[0, 1, 1],
	 	[0, 0, 1],
	 	[0, 1, 1]]: 13,
	[
		[1, 1, 1],
	 	[1, 0, 1],
	 	[1, 1, 1]]: 14,
	[
		[1, 1, 0],
	 	[1, 0, 0],
	 	[1, 1, 0]]: 15,
	[
		[0, 1, 1],
	 	[0, 0, 1],
	 	[0, 0, 0]]: 16,
	[
		[1, 1, 1],
	 	[1, 0, 1],
	 	[0, 0, 0]]: 17,
	[
		[1, 1, 0],
	 	[1, 0, 0],
	 	[0, 0, 0]]: 18,
	[
		[0, 0, 0],
	 	[1, 0, 1],
	 	[0, 1, 0]]: 19,
	[
		[0, 1, 0],
	 	[0, 0, 1],
	 	[0, 1, 0]]: 20,
	[
		[0, 1, 0],
	 	[1, 0, 0],
	 	[0, 1, 0]]: 21,
	[
		[0, 1, 0],
	 	[1, 0, 1],
	 	[0, 0, 0]]: 22,
	[
		[0, 0, 0],
	 	[1, 0, 0],
	 	[0, 1, 0]]: 23,
	[
		[0, 1, 0],
	 	[0, 0, 1],
	 	[0, 0, 0]]: 24,
	[
		[0, 1, 0],
	 	[1, 0, 1],
	 	[1, 1, 1]]: 25,
	[
		[0, 0, 0],
	 	[1, 0, 1],
	 	[0, 1, 1]]: 26,
	[
		[0, 1, 0],
	 	[1, 0, 0],
	 	[1, 1, 0]]: 27,
	[
		[0, 1, 1],
	 	[1, 0, 1],
	 	[0, 1, 1]]: 28,
	[
		[1, 1, 0],
	 	[1, 0, 1],
	 	[1, 1, 0]]: 29,
	[
		[0, 1, 0],
	 	[0, 0, 1],
	 	[0, 1, 1]]: 30,
	[
		[0, 0, 0],
	 	[1, 0, 1],
	 	[1, 1, 0]]: 31,
	[
		[0, 1, 1],
	 	[0, 0, 1],
	 	[0, 1, 0]]: 32,
	[
		[1, 1, 0],
	 	[1, 0, 1],
	 	[0, 0, 0]]: 33,
	[
		[1, 1, 1],
	 	[1, 0, 1],
	 	[0, 1, 0]]: 34,
	[
		[0, 1, 1],
	 	[1, 0, 1],
	 	[0, 0, 0]]: 35,
	[
		[1, 1, 0],
	 	[1, 0, 0],
	 	[0, 1, 0]]: 36,
	[
		[0, 1, 0],
	 	[1, 0, 1],
	 	[0, 1, 0]]: 37,
	[
		[1, 1, 0],
	 	[1, 0, 1],
	 	[0, 1, 0]]: 38,
	[
		[0, 1, 1],
	 	[1, 0, 1],
	 	[0, 1, 0]]: 39,
	[
		[0, 1, 0],
	 	[1, 0, 1],
	 	[0, 1, 1]]: 40,
	[
		[0, 1, 0],
	 	[1, 0, 1],
	 	[1, 1, 0]]: 41,
	[
		[1, 1, 0],
	 	[1, 0, 1],
	 	[0, 1, 1]]: 42,
	[
		[0, 1, 1],
	 	[1, 0, 1],
	 	[1, 1, 0]]: 43,
	[
		[1, 1, 0],
	 	[1, 0, 1],
	 	[1, 1, 1]]: 44,
	[
		[0, 1, 1],
	 	[1, 0, 1],
	 	[1, 1, 1]]: 45,
	[
		[1, 1, 1],
	 	[1, 0, 1],
	 	[1, 1, 0]]: 46,
	[
		[1, 1, 1],
	 	[1, 0, 1],
	 	[0, 1, 1]]: 47,
}


# Builds the 3x3 pattern for `offset`, using is_same(neighbor_offset) to test
# whether a given neighbor position counts as "same type". Works for both an
# in-hand piece (is_same = offset is one of the piece's own cells) and the
# placed grid (is_same = that grid cell has the same building type).
static func neighbor_pattern(offset: Vector2i, is_same: Callable) -> Array:
	var u = int(is_same.call(offset + Vector2i(0, -1)))
	var d = int(is_same.call(offset + Vector2i(0, 1)))
	var l = int(is_same.call(offset + Vector2i(-1, 0)))
	var r = int(is_same.call(offset + Vector2i(1, 0)))
	var ul := int(is_same.call(offset + Vector2i(-1, -1))) * int(min(u, l))
	var ur := int(is_same.call(offset + Vector2i(1, -1))) * int(min(u, r))
	var dl := int(is_same.call(offset + Vector2i(-1, 1))) * int(min(d, l))
	var dr := int(is_same.call(offset + Vector2i(1, 1))) * int(min(d, r))
	return [
		[ul, u, ur],
		[l, 0, r],
		[dl, d, dr],
	]


static func tile_for_pattern(pattern: Array) -> int:
	return CONNECTIVITY_TILE.get(pattern, 1)


static func tile_for(offset: Vector2i, occupied: Array[Vector2i]) -> int:
	return tile_for_pattern(neighbor_pattern(offset, func(p): return occupied.has(p)))
