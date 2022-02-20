<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ClusteredGrid

**Extends:** [Node2D](../Node2D)

## Description

A Wrapper Class that creates a normal `Grid` and a `Grid` of Clusters for the
normal `Grid`

## Property Descriptions

### grid

```gdscript
var grid: Grid
```

a normal `Grid` instance, with clusters enabled

### cluster\_grid

```gdscript
var cluster_grid: Grid
```

an empty `Grid` instance, where the tiles are the clusters of `grid`

### enable\_cluster\_area

```gdscript
var enable_cluster_area: bool
```

pass this in the `args` Dictionary to `_init()`,
to create a `CollisionPolygon2D` for every cluster under an `Area2D` in `cluster_grid`

## Method Descriptions

### \_init

```gdscript
func _init(_dimensions: Vector2, _tiles, args: Dictionary, _xscene_defaults: Dictionary)
```

takes the same arguments as `Grid._init()`
`args.cluster_dimensions: Vector2` must be given
`_dimensions` has to be evenly divisible by `args.cluster_dimensions`
if `args.enable_cluster_area`: `cluster_grid` is no longer empty
but of the following structure:
`cluster_grid`
	\ |-`Area2D`
	\   |-`XScene`
	\   |-`CollisionPolygon2D`
	\   |-`CollisionPolygon2D`
	\   |-...
with each `CollisionPolygon2D` representing a cluster and being a `shape_owner` under `Area2D`