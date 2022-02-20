# A Wrapper Class that creates a normal `Grid` and a `Grid` of Clusters for the normal `Grid`
extends Node2D

class_name ClusteredGrid, 'res://addons/grid/grid16.png'


# a normal `Grid` instance, with clusters enabled
var grid: Grid

# an empty `Grid` instance, where the tiles are the clusters of `grid`
var cluster_grid: Grid

# pass this in the `args` Dictionary to `_init()`, \
# to create a `CollisionPolygon2D` for every cluster under an `Area2D` in `cluster_grid`
var enable_cluster_area: bool

# takes the same arguments as `Grid._init()` \
# `args.cluster_dimensions: Vector2` must be given \
# `_dimensions` has to be evenly divisible by `args.cluster_dimensions` \
# if `args.enable_cluster_area`: `cluster_grid` is no longer empty \
# but of the following structure: \
# `cluster_grid` \
#	\ |-`Area2D` \
#	\   |-`XScene` \
#	\   |-`CollisionPolygon2D` \
#	\   |-`CollisionPolygon2D` \
#	\   |-... \
# with each `CollisionPolygon2D` representing a cluster and being a `shape_owner` under `Area2D`
func _init(_dimensions: Vector2, _tiles, args := {}, _xscene_defaults := {}):
	assert('cluster_dimensions' in args and args.cluster_dimensions is Vector2)
	assert(
		(
			int(_dimensions.x) % int(args.cluster_dimensions.x) == 0
			and int(_dimensions.y) % int(args.cluster_dimensions.y) == 0
		),
		'ClusteredGrid._init: _dimensions has to be evenly divisible by args.cluster_dimensions'
	)

	grid = Grid.new(_dimensions, _tiles, args, _xscene_defaults)
	enable_cluster_area = args.enable_cluster_area


func _ready():
	add_child(grid)

	var cluster_grid_dimensions = Vector2(
		grid.dimensions.x / grid.cluster_dimensions.x,
		grid.dimensions.y / grid.cluster_dimensions.y
		)

	var cluster_args = {
		tile_dimensions = grid.cluster_dimensions * grid.tile_dimensions,
		}

	var cluster_xscene_defaults = grid.xscene_defaults.duplicate()

	var cluster_tiles = {}
	if enable_cluster_area:
		var area = Area2D.new()
		cluster_xscene_defaults.x_root = area
		cluster_tiles.coll_poly = CollisionPolygon2D


	cluster_grid = Grid.new(cluster_grid_dimensions, cluster_tiles, cluster_args, cluster_xscene_defaults)
	add_child(cluster_grid)

	if enable_cluster_area:
		var poly = cluster_grid._get_polygon_of_tile(0)
		for i in cluster_grid.size:
			cluster_grid.x.x(i).polygon = poly
			# cluster_grid.x.x(i).shape_owner_set_transform(0, self.transform)
