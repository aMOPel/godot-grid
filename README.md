![grid](./grid64.png)

# godot-grid

A gdscript library to make working with rectangular grids easier.

__When to use it:__
  * You need access to every sprite in the grid and plan to manipulate them by code.
  * You want to generate the grid of sprites from code.

__When not to use it:__
  * You don't need to access the tiles from code.
  * You want to make the grid from the editor by hand. Use tilemaps for that.

## Preview

__Make patterns:__
![](./tutorial/pics/readme_pattern.png)

__Easily work with Columns, Rows and Diagonals:__
![](./tutorial/pics/readme_moving_neighbors.gif)

__Clusters and Collision:__
![](./tutorial/pics/collision_moving_example.gif)

## [Tutorial](./tutorial/README.md) (to see all Features)

## Applications
It's supposed to be useful when you have some sort of rectangular grid based system in your game.

  * tetris
  * chess
  * grid based puzzles
  * grid based combat
  * ...

## Performance

Since every Tile is a Node (with potential children), you will get lags from 10k nodes upwards depending on the machine.

So this library is intended for comparativly small Grids.

Some features just use static information and thus are quite fast (the look up tables).
This includes the initial generation of Grid.

But others generate Arrays depending on the input and can become quite sluggish, when those arrays get too big.
See ['Access relative to a Tile' Chapter in the Tutorial](./tutorial/README.md)

Other Performance Tips:
* make sure to only put `PackedScenes` in `Grid.tiles`, because putting `Nodes` requires the use of `Nodes.duplicate()` which is slow
* removing a lot of nodes with `XScene.remove_scene()`, tends to be slow, simply because freeing nodes or detaching them from the tree is expensive

## Installation

_Made with Godot version 3.4.2.stable.official.45eaa2daf_

This plugin depends on [XScene](https://github.com/aMOPel/godot-xchange-scene#installation)
You have to install it aswell.

This repo is in a __Godot Plugin format__.

You can:
<!-- - (Not yet) Install it via [__AssetLib__](https://godotengine.org/asset-library/asset/1018) or -->
- [Download](https://github.com/aMOPel/godot-grid/archive/refs/heads/master.zip)
   the __.zip__ of this repo and unpack it into your project, __currently XScene is included in the .zip__


For more details, read the [godot docs on installing Plugins
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

__Don't forget to enable it in your project settings!__

## Future Feature Ideas

  * support for hex grid
  * support for triangular grid
  * support for isometric grid
  * you can open an issue if you're missing a feature

## Attributions

<a href="https://www.flaticon.com/free-icons/menu" title="menu icons">Menu icons created by Kiranshastry - Flaticon</a>
