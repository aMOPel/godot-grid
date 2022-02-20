<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# Grid

**Extends:** [Node2D](../Node2D)

## Description

A gdscript library to make working with rectangular grids easier.

## Property Descriptions

### dimensions

```gdscript
var dimensions: Vector2
```

dimensions of the grid \
number of cols/rows in the grid

### rect

```gdscript
var rect: Rect2
```

Rect2 encompassing the whole grid \
coordinates are local to the grid

### polygon

```gdscript
var polygon: PoolVector2Array
```

polygon encompassing the whole grid \
4 corners of the grid \
coordinates are local to the grid

### enable\_area

```gdscript
var enable_area: bool
```

pass this in the `args` Dictionary to `_init()`, to enable the `Grid.area` property

### area

```gdscript
var area: Area2D
```

`Area2D` with `CollisionPolygon2D` child with `.polygon == Grid.polygon` \
pass `enable_area` in the `args` Dictionary to `_init()`, to enable this property \
when enabled, `area` gets added as a child Node to the grid

### pattern

```gdscript
var pattern: Array
```

pattern of `tile_key`s that is applied to the grid \
setting this variable is expensive as it resets the whole grid

### distribution

```gdscript
var distribution
```

distribution of `tile_key`s that is applied to the grid \
can be Array if `tile_key`s are int or dictionary if `tile_key`s are String \
setting this variable is expensive as it resets the whole grid

### map

```gdscript
var map: Array
```

maps `grid_index` to `tile_key` \
setting this variable is expensive as it resets the whole grid

### size

```gdscript
var size: int
```

number of tiles in grid

### tile\_dimensions

```gdscript
var tile_dimensions: Vector2
```

dimensions of an individual tile \
using normal coordinates, not grid coordinates

### cluster\_dimensions

```gdscript
var cluster_dimensions: Vector2
```

dimensions of an individual cluster \
using grid coordinates, so the unit is 'tiles'

### cluster\_lut

```gdscript
var cluster_lut: Array
```

groups indices of clusters together for easy access, since they are constant \
Array of Arrays containing `grid_indices`

### row\_lut

```gdscript
var row_lut: Array
```

groups indices of rows together for easy access, since they are constant \
Array of Arrays containing `grid_indices`

### col\_lut

```gdscript
var col_lut: Array
```

groups indices of columns together for easy access, since they are constant \
Array of Arrays containing `grid_indices`

### falling\_diag\_lut

```gdscript
var falling_diag_lut: Array
```

groups indices of falling diagonals together for easy access, since they are constant \
Array of Arrays containing `grid_indices`

### rising\_diag\_lut

```gdscript
var rising_diag_lut: Array
```

groups indices of rising diagonals together for easy access, since they are constant \
Array of Arrays containing `grid_indices`

### g

```gdscript
var g: Array
```

holds information for all tiles in the grid \
`g` at `grid_index` is `{position: Vector2, tile_key: int/string, grid_position: Vector2, rising_diag: int, falling_diag:int}`

### tiles

```gdscript
var tiles: Dictionary
```

keys are `tile_key`, values are Node/PackedScene

### xscene\_defaults

```gdscript
var xscene_defaults: Dictionary
```

defaults for `XScene.defaults`, only set once in `_ready()`

### x

```gdscript
var x: XScene
```

instance of `XScene`, managing all tiles of the grid

## Method Descriptions

### \_init

```gdscript
func _init(_dimensions: Vector2, _tiles, args: Dictionary, _xscene_defaults: Dictionary)
```

instance a grid with `_dimensions.x` columns and `_dimensions.y` rows. By default all tiles are visible and are set to the first tile in `_tiles` \
`_tiles` can be empty, then no Nodes will be added under the grid, but the luts are still generated \
values in `_tiles` can be PackagedScene/Node/Object, but Node is slow \
`var default_args = { pattern = [], distribution = {}, tile_dimensions = Vector2.ZERO, enable_area = false, cluster_dimensions = Vector2.ZERO, }` \
`args.pattern` is a matrix of `tile_key`s that is repeated through the whole grid. \
`args.distribution` is relative probability of tiles by which they get randomly distributed through the grid. Can be Array or Dictionary. \
You can only specify either `args.pattern` or `args.distribution` \
`if args.tile_dimensions == Vector2.ZERO`: The size of the icon is inferred from first tile in `_tiles` \
`else`: It's up to you to assure that `args.tile_dimensions.x` and `args.tile_dimensions.y` are correct \
`if args.enable_area`: an `Area2D` for the whole Grid is added as a child \
`if args.cluster_dimensions`: the cluster feature is enabled with the the specified cluster size \
`xscene_defaults` are send through to `XScene.new()` at `Grid._ready()`, see XScene for documentation \

### to\_location

```gdscript
func to_location(partial_location) -> Dictionary
```

`partial_location` can be `grid_index: int` or `grid_position: Vector2` or `{grid_index: int}` or `{grid_position: Vector2}` or `{grid_index: int, grid_position: Vector2}` \
`grid_index` takes precedence over `grid_position` \
it returns the corresponding `location` `{grid_index: int, grid_position: Vector2}`

### change\_tile

```gdscript
func change_tile(partial_location, changes: Dictionary, args: Dictionary, xscene_args: Dictionary) -> void
```

change the tile at `partial_location` \
`changes` can contain these keys: `{tile_key: int, state: int, partial_location: see to_location()}` \
`if changes.tile_key`: `switch_tile()` is used to switch to `changes.tile_key` \
`if changes.state`: `x.change_scene()` is used to change to `changes.state` \
`if changes.partial_location`: `move_tile()` is used to move to `changes.partial_location` \
`args` are send through to `move_tile()` and `switch_tile()` \
`xscene_args` are send through to XScene, see XScene for documentation

### switch\_tile

```gdscript
func switch_tile(partial_location, tile_key, args: Dictionary, xscene_args: Dictionary) -> void
```

Switch the tile at `partial_location` to the tile of `tile_key`. \
`if args.save_node`: the old tile/node is STOPPED (or HIDDEN) and kept, \
if you switch back to the old `tile_key` in the future, the saved node is reattach to the tree \
this is quicker but costs more memory \
`else`: The old tile is freed, no properties are kept, except the position. \
this is slower but costs less memory \
`xscene_args` are send through to XScene, see XScene for documentation

### move\_tile

```gdscript
func move_tile(partial_location_to, partial_location_from, args: Dictionary, xscene_args: Dictionary) -> void
```

Move the tile at `partial_location_from` to `partial_location_to`. \
`if args.leave_behind == null`: it performs a swap with the tile at `partial_location_to` \
`else`: it uses `args.leave_behind` as a `tile_key` for `switch_tile()` at `partial_location_from` \
`args.save_node` is passed to `switch_tile()` \
`xscene_args` are send through to XScene, see XScene for documentation

### make\_map\_for\_pattern

```gdscript
func make_map_for_pattern(_pattern: Array) -> Array
```

Makes an array of size `grid.size`, that maps `tile_key` from `grid.tiles` to `grid_index`, according to `_pattern`

### make\_map\_for\_distribution

```gdscript
func make_map_for_distribution(_distribution) -> Array
```

Makes an array of size `grid.size`, that maps `tile_key` from `grid.tiles` to `grid_index`, randomly distributed according to `_distribution`

### get\_cols\_rows\_around

```gdscript
func get_cols_rows_around(partial_location, distance: int = -1) -> Dictionary
```

get row indices and col indices around `partial_location` depending on `distance` \
`if distance == -1`: get all rows/cols \
returns `{rows = {above: Array, below: Array}, cols = {left: Array, right: Array}}` \
the Arrays are ordered "closest to `location`" first

### get\_rings\_around

```gdscript
func get_rings_around(partial_location, distance: int = 1) -> Array
```

returns an Array of Arrays containing the `grid_indices` of the tiles in the next 'ring' around `partial_location` \
`distance` determines how many rings are returned \
`if distance == -1`: it returns all rings

### get\_orthogonal\_neighbors

```gdscript
func get_orthogonal_neighbors(partial_location, distance: int = 1, rings: bool = false) -> Array
```

returns an Array containing the `grid_indices` of the tiles in the same row and column as `partial_location` \
`if rings`: see `get_rings_around()`, but only with tiles in same row and column \
`distance` determines how many rings are returned \
`if distance == -1`: it returns all rings

### get\_diagonal\_neighbors

```gdscript
func get_diagonal_neighbors(partial_location, distance: int = 1, rings: bool = false) -> Array
```

returns an Array containing the `grid_indices` of the tiles on the same diagonals as `partial_location` \
`if rings`: see `get_rings_around()`, but only with tiles on same diagonals \
`distance` determines how many rings are returned \
`if distance == -1`: it returns all rings

### get\_all\_neighbors

```gdscript
func get_all_neighbors(partial_location, distance: int = 1, rings: bool = false) -> Array
```

combines `get_orthogonal_neighbors()` and `get_diagonal_neighbors()`

### get\_distance\_between

```gdscript
func get_distance_between(partial_location_to, partial_location_from) -> Dictionary
```

returns a location Dictionary, see `to_location()`, \
containing the differences between `partial_location_to` and `partial_location_from` \

### get\_rect\_between

```gdscript
func get_rect_between(partial_location_to, partial_location_from) -> Array
```

returns an Array containing the `grid_indices` of all tiles in the rectangle between and including `partial_location_to` and `partial_location_from` \
the order of the inputs does not matter

### get\_tiles\_by\_tile\_key

```gdscript
func get_tiles_by_tile_key(_tile_key) -> Array
```

get Array of tiles with the specified `tile_key`