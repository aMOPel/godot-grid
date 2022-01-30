extends Sprite

class_name Tile, "res://addons/grid/tile16.png"

var column: int
var row: int
var grid_index: int
var tile_key setget _set_tile_key
var data:= {}

onready var parent := get_parent()


func _ready():
	assert(parent is Grid, 'the parent node to a Tile should be a Grid')
	parent.connect('ready', self, '_on_parent_ready')


func _on_parent_ready():
	column = position.x / parent.tile_x
	row = position.y / parent.tile_y


func _set_tile_key(new) -> void:
	assert(new in parent.tiles, 'setting tile_key to a value thats not in (parent)Grid.tiles')
	tile_key = new
