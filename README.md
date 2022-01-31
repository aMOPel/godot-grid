![grid](https://raw.githubusercontent.com/aMOPel/godot-grid/master/grid64.png)

# godot-grid

A gdscript library to make working with rectangular grids easier.

__WIP__ I saw the jam a little too late and couldn't quite get the project where I wanted it to.

__When to use it:__
  * You need access to every sprite in the grid and plan to manipulate them by code.
  * You want to generate the grid of sprites from code.

__When not to use it:__
  * You don't need to access the tiles from code.
  * You want to make the grid from the editor by hand. Use tilemaps for that.

### Idea
This plugin's system is similar to an LCD screen. It makes a `Grid` of `Tile`s (Pixels) and lets you turn them on or off (using `XScene`)
or change the `Color` (with `modulate`), or change the `Texture` (that's where the metaphor breaks).
However it is no intended that the `Tile`s are move around separately.
Instead you can keep an index of what `Tiles` should have what `Color`/`Texture` and redraw the `Grid` accordingly.

Two classes are defined, `Grid` and `Tile`.

A `Grid` inherits from `Node2D`. It uses my other godot plugin
[XScene](https://github.com/aMOPel/godot-xchange-scene) to manage the `Nodes` below `Grid`, which are gonna be of class `Tile`
(See [Features](#Features) to see what `XScene` is good for).
Through the `Grid` class you can then access and manipulate the `Tile`s from code.

A `Tile` inherits from `Sprite`. In the editor or by code you can add a texture and manipulate the `Tile` scene however you want.
The root of the scene should be of type `Tile` however.
Then by code you specify all the `Tile` scenes (optionally multiple) you want to add the the `Grid` and
`Grid` generates a literal grid from it according to your specifications.

In [`example/Main.gd`](example/Main.gd)
is a godot project, that explains in detail how to use it.

### Applications
It's supposed to be useful when you have some sort of rectangular grid based system in your game.

  * tetris
  * chess
  * grid based puzzles
  * inventory maybe
  * grid based turn based combat maybe
  * ...

### Features
  * specify multiple `Tiles` which can be switched in place in the `Grid`
  * `Tiles` can be scenes (`.tscn`), this enables utilization of the full power of the scene system
  * generate a `Grid` of `Tiles`, with different textures etc. 
    * with a specified amount of rows and columns and
    * according to a pattern or
    * randomly according to a distribution
  * access and manipulate `Tiles`
    * access by index
    * access by row and column
    * access whole rows / columns
    * access all `Tiles` of the same scene
  * using [XScene](https://github.com/aMOPel/godot-xchange-scene) 
    * to access `Tiles` that are active/hidden/stopped
    * to manipulate the state (active/hidden/stopped/freed) of `Tiles` easily


### Installation

_Made with Godot version 3.4.2.stable.official.45eaa2daf_

This plugin depends on [XScene](https://github.com/aMOPel/godot-xchange-scene#installation)
You have to install it aswell.

This repo is in a __Godot Plugin format__.

You can:
- (Not yet) Install it via [__AssetLib__](https://godotengine.org/asset-library/asset/1018) or
- Download a __.zip__ of this repo and put it in your project

For more details, read the [godot docs on installing Plugins
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

__Don't forget to enable it in your project settings!__

### Run examples

To run the examples yourself, you can
1. Clone this repo 
`git clone https://github.com/aMOPel/godot-grid.git godot-grid`
2. Run godot in it (eg. using linux and bash)
`cd godot-grid; godot --editor`
3. Comment and uncomment the functions in [__example/Main.gd__](example/Main.gd) `_ready()`
4. Run the main scene in godot

### TODO

  * diagonal support
  * helpers for area around `Tile`
  * you can open an issue if you're missing a feature

### Attributions
<a href="https://www.flaticon.com/free-icons/shape" title="shape icons">Shape icons created by Dave Gandy - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/menu" title="menu icons">Menu icons created by Kiranshastry - Flaticon</a>
