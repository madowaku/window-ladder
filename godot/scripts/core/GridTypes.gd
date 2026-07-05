class_name GridTypes
extends RefCounted

enum TileType {
	EMPTY,
	GROUND,
	LEDGE,
	WALL,
	WINDOW_DIRTY,
	WINDOW_CLEAN,
	CAT_WINDOW,
	ENTERABLE_WINDOW,
}

const SYMBOL_TO_TILE := {
	".": TileType.EMPTY,
	"G": TileType.GROUND,
	"L": TileType.LEDGE,
	"#": TileType.WALL,
	"D": TileType.WINDOW_DIRTY,
	"W": TileType.WINDOW_CLEAN,
	"C": TileType.CAT_WINDOW,
	"E": TileType.ENTERABLE_WINDOW,
}

const TILE_TO_SYMBOL := {
	TileType.EMPTY: ".",
	TileType.GROUND: "G",
	TileType.LEDGE: "L",
	TileType.WALL: "#",
	TileType.WINDOW_DIRTY: "D",
	TileType.WINDOW_CLEAN: "W",
	TileType.CAT_WINDOW: "C",
	TileType.ENTERABLE_WINDOW: "E",
}

static func tile_from_symbol(symbol: String) -> int:
	return SYMBOL_TO_TILE.get(symbol, TileType.EMPTY)


static func symbol_from_tile(tile: int) -> String:
	return TILE_TO_SYMBOL.get(tile, ".")


static func is_window(tile: int) -> bool:
	return tile == TileType.WINDOW_DIRTY or tile == TileType.WINDOW_CLEAN or tile == TileType.CAT_WINDOW or tile == TileType.ENTERABLE_WINDOW


static func is_solid_for_ladder(tile: int) -> bool:
	return tile == TileType.WALL or is_window(tile)


static func is_floor(tile: int) -> bool:
	return tile == TileType.GROUND or tile == TileType.LEDGE
