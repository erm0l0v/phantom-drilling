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

# Bitmask of which sides of a cell touch another occupied cell of the same
# piece (UP=1, DOWN=2, LEFT=4, RIGHT=8) -> 1-based tile index into
# baseBuildingTiles.png (a 22x1 sheet of 32x32 tiles, index n at column n-1).
# Picking the tile this way means connected cells render seamlessly, with no
# border on the shared edge. Derived from tmp/with_numbers.png.
const CONNECTIVITY_TILE := {
	0: 1,  # isolated
	1: 6,  # up
	2: 5,  # down
	3: 7,  # up+down
	4: 4,  # left
	5: 18,  # up+left
	6: 12,  # down+left
	7: 15,  # up+down+left
	8: 2,  # right
	9: 16,  # up+right
	10: 10,  # down+right
	11: 13,  # up+down+right
	12: 3,  # left+right
	13: 17,  # up+left+right
	14: 11,  # down+left+right
	15: 14,  # up+down+left+right
}


static func connectivity_mask(offset: Vector2i, occupied: Array[Vector2i]) -> int:
	var mask := 0
	if occupied.has(offset + Vector2i(0, -1)):
		mask |= 1
	if occupied.has(offset + Vector2i(0, 1)):
		mask |= 2
	if occupied.has(offset + Vector2i(-1, 0)):
		mask |= 4
	if occupied.has(offset + Vector2i(1, 0)):
		mask |= 8
	return mask


static func tile_for(offset: Vector2i, occupied: Array[Vector2i]) -> int:
	return CONNECTIVITY_TILE[connectivity_mask(offset, occupied)]
