# __robust, high level interface__ for manipulating and indexing scenes below a
# given `Node`.
class_name XScene

extends Node

# warnings-disable

# enum with the scene state \
# `ACTIVE` = 0 uses `add_child()` \
# `HIDDEN` = 1 uses `.hide()` \
# `STOPPED` = 2 uses `remove_child()` \
# `FREE` = 3 uses `.free()`
enum { ACTIVE, HIDDEN, STOPPED, FREE }

# Dictionary that holds all indexed scenes and their state \
# has either `count` or String as keys \
# Eg. {1:{scene:[Node2D:1235], state:0}, abra:{scene:[Node2D:1239], state:1}}
var scenes := {} setget _dont_set, get_scenes
# Array of keys of active scenes
var active := [] setget _dont_set, get_active
# Array of keys of hidden scenes
var hidden := [] setget _dont_set, get_hidden
# Array of keys of stopped scenes
var stopped := [] setget _dont_set, get_stopped

# the Node below which this class will manipulate scenes
var root: Node setget _dont_set
# wether to synchronize `scenes` with external additions to the tree \
# __WARNING__ this can be slow, read the __Caveats__ Section in the README.md
var flag_sync: bool setget _dont_set

# true if currently adding a scene \
# this is interesting for the sync feature and deferred adding
var _adding_scene := false setget _dont_set
# true if currently removing a scene \
# this is interesting for `_check_scene()` and deferred removing
var _removing_scene := false setget _dont_set

# Dictionary that hold the default values for parameters used in add/show/remove \
# any invalid key or value assignment will throw an error to prevent misuse and cryptic errors \
# you can assign partial dictionaries and it will override as expected, leaving the other keys alone \
# eg `x.defaults = {deferred = true, method_add = 2}` \
# `x.defaults = x._original_defaults` to reset
# `deferred` = false, \
# `recursive_owner` = false, \
# `method_add` = ACTIVE, \
# `method_remove` = FREE, \
# `count_start` = 1 | This is only applied when passing it to the _init() of XScene
var defaults: Dictionary setget set_defaults

# constant original default values, used for comparison in `set_defaults()` and to reset
const _original_defaults := {
	deferred = false,
	recursive_owner = false,
	method_add = ACTIVE,
	method_remove = FREE,
	count_start = 0
}

# automatically incrementing counter used as key when none is provided \
# starting value can be set by passing `defaults` when initializing XScene \
# defaults to 1
var count: int setget _dont_set


# init for XScene \
# `node`: Node | determines `root` \
# `synchronize`: bool | default: false | wether to synchronize `scenes` with \
# external additions to the tree \
# `parameter_defaults`: Dictionary | default: {} | this is the only way to change `count_start` \
# you can also pass partial dictionaries
# eg `x = XScene.new($Node, false, {deferred = true, count_start = 0})`
func _init(node: Node, synchronize := false, parameter_defaults := {}) -> void:
	assert(
		node.is_inside_tree(),
		(
			"XScene._init: failed to initilize, given node isn't in scenetree"
			+ node.to_string()
		)
	)
	flag_sync = synchronize
	defaults = _original_defaults.duplicate()
	self.defaults = parameter_defaults
	count = defaults.count_start

	root = node
	node.add_child(self)


func _ready() -> void:
	# for syncing nodes that are added by something other than this class
	if flag_sync:
		get_tree().connect("node_added", self, "_on_node_added")
		# this adds existing child scenes of root to scenes, except self
		var children = root.get_children()
		if children:
			for s in children:
				if s != self:
					_on_node_added(s)


func _dont_set(a) -> void:
	assert(false, "XScene: do not set any property, except defaults in XScene manually")


# setting defaults Dictionary, any invalid keys or values will throw an error 
func set_defaults(d: Dictionary) -> void:
	for k in d:
		assert( k in _original_defaults, "XScene.set_defaults: invalid key " + k as String)
		assert(typeof(_original_defaults[k]) == typeof(d[k]), 
		"XScene.set_defaults: value of key is of wrong type " + k as String + " " + d[k] as String)
		if k == "method_add":
			assert(ACTIVE <= d[k] and d[k] <= STOPPED, 
			"XScene.set_defaults: method_add must be ACTIVE/HIDDEN/STOPPED " + d[k] as String)
		if k == "method_remove":
			assert(HIDDEN <= d[k] and d[k] <= FREE, 
			"XScene.set_defaults: method_remove must be HIDDEN/STOPPED/FREE " + d[k] as String)
		if k == "count_start":
			assert(d[k] >= 0, 
			"XScene.set_defaults: count_start must be >= 0 " + d[k] as String)
		defaults[k] = d[k]


func get_active() -> Array:
	_check_scenes(ACTIVE)
	return active


func get_hidden() -> Array:
	_check_scenes(HIDDEN)
	return hidden


func get_stopped() -> Array:
	_check_scenes(STOPPED)
	return stopped


func get_scenes() -> Dictionary:
	_check_scenes()
	return scenes


# "x"ess the scene of `key` \
# returns null, if the scene of `key` was already freed or is queued for deletion
func x(key) -> Node:
	if _check_scene(key):
		return scenes[key].scene
	else:
		print_debug("XScene.x: returning null, key invalid " + key as String)
		return null


# do multiple "x"ess"s", get Array of Nodes based on `method` \
# if null, return all scenes(nodes) from `scenes` \
# if method specified, return only the scenes(nodes) in the respective state \
# `method`: null / `ACTIVE` / `HIDDEN` / `STOPPED` | default: null
func xs(method = null) -> Array:
	assert(
		method == null or (ACTIVE <= method and method <= STOPPED),
		"XScene.xs: invalid method value " + "null" if method == null else method as String
	)
	_check_scenes(method)
	var a := []
	if method == null:
		for k in scenes.keys():
			a.push_back(scenes[k].scene)
	else:
		for k in scenes.keys():
			if scenes[k].state == method:
				a.push_back(scenes[k].scene)
	if a.empty():
		print_debug(
			(
				"XScene.xs: not returning any nodes with method=" + "null"
				if method == null
				else method as String
			)
		)
	return a


# add a scene to the tree below `root` and to `scenes` \
# `ACTIVE` uses `add_child()` \
# `HIDDEN` uses `add_child()` and `.hide()` \
# `STOPPED` only adds to `scenes` not to the tree \
# `scene`: Node / PackagedScene \
# `key`: `count` / String | default: `count` | key in `scenes` \
# `method`: `ACTIVE` / `HIDDEN` / `STOPPED` | default: `ACTIVE` \
# `deferred`: bool | default: false | whether to use call_deferred() for tree
# changes \
# `recursive_owner`: bool | default: false | wether to recursively for all
# children of `scene` set the owner to `root`, this is useful for `pack_root()`
func add_scene( new_scene, key = count, method := defaults.method_add, deferred := defaults.deferred, recursive_owner := defaults.recursive_owner) -> void:
	assert(
		key is int or key is String,
		"XScene.add_scene: key must be count or String " + key as String
	)
	assert(
		! (key in scenes),
		"XScene.add_scene: key already exists " + key as String
	)
	assert(
		ACTIVE <= method and method <= STOPPED,
		"XScene.add_scene: invalid method value " + method as String
	)
	var s: Node
	if new_scene is PackedScene:
		s = new_scene.instance()
	elif new_scene is Node:
		s = new_scene
	else:
		assert(
			false,
			(
				"XScene.add_scene: new_scene must be PackedScene or Node "
				+ new_scene.to_string()
			)
		)

	if method != STOPPED:
		_adding_scene = true
		if deferred:
			root.call_deferred("add_child", s)
			# count must be incremented before yield
			if key is int:
				count += 1
			yield(s, "tree_entered")
		else:
			root.add_child(s)
			if key is int:
				count += 1
		_adding_scene = false

		if recursive_owner:
			s.propagate_call("set_owner", [root])
		else:
			s.owner = root

		if method == HIDDEN:
			if not s is CanvasItem:
				print_debug(
					(
						"XScene.add_scene: new_scene must inherit from CanvasItem to be hidden "
						+ s.to_string()
					)
				)
			else:
				s.hide()

	scenes[key] = {scene = s, state = method}


# make `key` visible, and update `scenes` \
# it uses `_check_scene` to verify that the Node is still valid \
# if key is `HIDDEN` it uses `.show()` \
# if key is `STOPPED` it uses `add_child()` and `.show()` \
# `key` : int / String | default: `count` | key in `scenes` \
# `deferred` : bool | default: false | whether to use `call_deferred()` for tree
# changes
func show_scene(key = count, deferred := defaults.deferred) -> void:
	if not _check_scene(key):
		push_error("XScene.show_scene: key invalid " + key as String)
		return

	var s = scenes[key]

	match s.state:
		ACTIVE:
			# print_debug(
			# 	(
			# 		"XScene.show_scene: scene already active, aborting "
			# 		+ key as String
			# 		+ " "
			# 	)
			# 	, s
			# )
			return
		HIDDEN:
			if not s.scene is CanvasItem:
				print_debug(
					(
						"XScene.show_scene: scene must inherit from CanvasItem to be hidden "
					)
					, s
				)
				return
			s.scene.show()
		STOPPED:
			_adding_scene = true
			if deferred:
				root.call_deferred("add_child", s.scene)
				yield(s.scene, "tree_entered")
			else:
				root.add_child(s.scene)
			if s.scene is CanvasItem and not s.scene.visible:
				s.scene.show()
			_adding_scene = false
	s.state = ACTIVE


# remove `key` from `root` (or hide it) and update `scenes` \
# it uses `_check_scene` to verify that the Node is still valid \
# `HIDDEN` uses `.hide()` \
# `STOPPED` uses `remove_child()` \
# `FREE` uses `.free()` \
# `key`: int / String | default: `count` | key in `scenes` \
# `method`: `HIDDEN` / `STOPPED` / `FREE` | default: `FREE` \
# `deferred`: bool | default: false | whether to use `call_deferred()` or
# `queue_free()` for tree changes
func remove_scene( key = count, method := defaults.method_remove, deferred := defaults.deferred) -> void:
	assert(
		HIDDEN <= method and method <= FREE,
		"XScene.remove_scene: invalid method value " + method as String
	)
	if not _check_scene(key):
		push_error("XScene.remove_scene: key invalid " + key as String)
		return

	var s = scenes[key]

	match method:
		HIDDEN:
			if not s.scene is CanvasItem:
				print_debug(
					(
						"XScene.remove_scene: scene must inherit from CanvasItem to be hidden "
					)
					, s
				)
				return

			if s.state == ACTIVE:
				s.scene.hide()
				s.state = HIDDEN
		STOPPED:
			if s.state != STOPPED:
				if s.scene is CanvasItem and s.state == HIDDEN:
					s.scene.show()
				_removing_scene = true
				if deferred:
					root.call_deferred("remove_child", s.scene)
					s.state = STOPPED
					yield(s.scene, "tree_exited")
				else:
					root.remove_child(s.scene)
					s.state = STOPPED
				_removing_scene = false
		FREE:
			_removing_scene = true
			if deferred:
				s.scene.queue_free()
			else:
				s.scene.free()
			_removing_scene = false
			scenes.erase(key)


# use `show_scene(key_to, deferred)`
# and `remove_scene(key_from, method_from, deferred)` \
# `key_from`: int / String | default: null | use `remove_scene()` with this key, \
# if null, the last active scene will be used, mind that the order of `active`
# only depends on the order of `scenes`
# hiding/stopping and then showing scenes won't change the order \
# see `show_scene()` and `remove_scene()` for other parameters
func x_scene( key_to, key_from = null, method_from := defaults.method_remove, deferred := defaults.deferred) -> void:
	if key_from == null:
		key_from = self.active[-1]

	show_scene(key_to, deferred)
	remove_scene(key_from, method_from, deferred)


# use `add_scene(scene_to, key_to, method_to, deferred, recursive_owner)`
# and `remove_scene(key_from, method_from, deferred)`
# `key_to`: `count` / String | default: `count` | use `add_scene()` with this key \
# `key_from`: int / String | default: null | use `remove_scene()` with this key, \
# if null, the last active scene will be used, mind that the order of `active`
# only depends on the order of `scenes`
# hiding/stopping and then showing scenes won't change the order \
# see `add_scene()` and `remove_scene()` for other parameters
func x_add_scene( scene_to, key_to = count, key_from = null, method_to := defaults.method_add, method_from := defaults.method_remove, deferred := defaults.deferred, recursive_owner := defaults.recursive_owner) -> void:
	if key_from == null:
		key_from = self.active[-1]
	remove_scene(key_from, method_from, deferred)
	add_scene(scene_to, key_to, method_to, deferred, recursive_owner)


# adds multiple scenes with `add_scene()` \
# `scenes` : Array<Node or PackedScene> \
# `keys` : count / Array<String> | default: count | if it isn't count the Array has to be the same size as `scenes` \
# see `add_scene()` for other parameters
func add_scenes( new_scenes: Array, keys = count, method := defaults.method_add, deferred := defaults.deferred, recursive_owner := defaults.recursive_owner) -> void:
	if keys is int:
		assert(
			keys == count,
			(
				"XScene.add_scenes: key must be array if it isn't count "
				+ keys as String
			)
		)
		for s in new_scenes:
			add_scene(s, count, method, deferred, recursive_owner)
	elif keys is Array:
		assert(
			new_scenes.size() == keys.size(),
			(
				"XScene.add_scenes: new_scenes and keys must be same size "
				+ new_scenes as String
				+ " "
				+ keys as String
			)
		)
		for i in range(new_scenes.size()):
			add_scene(new_scenes[i], keys[i], method, deferred, recursive_owner)


# show multiple scenes with `show_scene()` \
# `keys` : Array<String and/or int> \
# see `show_scene()` for other parameters
func show_scenes(keys: Array, deferred := defaults.deferred) -> void:
	for k in keys:
		show_scene(k, deferred)


# removes multiple scenes with `remove_scene()` \
# `keys` : Array<String and/or int> \
# see `remove_scene()` for other parameters
func remove_scenes( keys: Array, method := defaults.method_remove, deferred := defaults.deferred) -> void:
	for k in keys:
		remove_scene(k, method, deferred)


# pack `root` into `filepath` using `PackedScene.pack()` and `ResourceSaver.save()` \
# this works together with the `recursive_owner` parameter of `add_scene()` \
# mind that the recursive_owner parameter is only necessary for scenes
# constructed from script, a scene constructed in the editor already works
func pack_root(filepath) -> void:
	var scene = PackedScene.new()
	if scene.pack(root) == OK:
		if ResourceSaver.save(filepath, scene) != OK:
			push_error(
				"XScene.pack_root: An error occurred while saving the scene to disk, using ResourceSaver.save()"
			)


# check multiple scenes with `_check_scene()` \
# this gets called by the getters for `scenes`, `active`, `hidden`, `stopped`
# and `xs()` \
# if null updates `scenes`, else update only the respective array \
# `method` null / `ACTIVE` / `HIDDEN` / `STOPPED` | default: null |
func _check_scenes(method = null) -> void:
	var dead_keys = []
	if method == null:
		for k in scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
	else:
		assert(
			ACTIVE <= method and method <= STOPPED,
			"XScene._check_scenes: invalid method value " + method as String
		)
		match method:
			ACTIVE:
				active = []
			HIDDEN:
				hidden = []
			STOPPED:
				stopped = []
		for k in scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
			else:
				if scenes[k].state == method:
					match method:
						ACTIVE:
							active.push_back(k)
						HIDDEN:
							hidden.push_back(k)
						STOPPED:
							stopped.push_back(k)
	# this is necessary because dict.erase() doesn't work while iterating over dict
	if not dead_keys.empty():
		for k in dead_keys:
			scenes.erase(k)
		print_debug(
			"XScene._check_scenes: these scenes were already freed: \n",
			dead_keys
		)


# check if `key` scene is still valid and update its state in `scenes` \
# if the scene is no longer valid it erases the key from `scenes` \
# it waits until after `remove_scene()` is done \
# `single` bool | default: true | has to be false when iterating over `scenes`, because you can't erase a key then
func _check_scene(key, single := true) -> bool:
	if key == null:
		return false
	if single:
		if ! (key in scenes):
			return false
	if _removing_scene:
		yield(get_tree(), "idle_frame")

	var s = scenes[key]

	if is_instance_valid(s.scene) and not s.scene.is_queued_for_deletion():
		if s.scene.is_inside_tree():
			if s.scene is CanvasItem:
				if s.scene.visible:
					s.state = ACTIVE
				else:
					s.state = HIDDEN
		else:
			if s.state != STOPPED:
				s.state = STOPPED
		return true
	else:
		if single:
			scenes.erase(key)
			print_debug(
				"XScene._check_scene: scene ", key, " was already freed"
			)
		return false


# add `node` to `scenes` with key = `count` if `node` is child of `root` \
# if `flag_sync` is true it is connected to the `get_tree()` `node_added` signal \
# also it gets called in `_ready()` to add preexisting nodes \
# it is skipped when adding nodes with `add_scene()` or `show_scene()`
func _on_node_added(node: Node) -> void:
	if _adding_scene:
		return
	if node.get_parent() == root:
		scenes[node.name] = {
			scene = node,
			state = (
				HIDDEN
				if (node is CanvasItem and not node.visible)
				else ACTIVE
			)
		}

		# count += 1


# print debug information
func debug() -> void:
	var s = ""
	s += "active: " + active as String + "\n"
	s += "hidden: " + hidden as String + "\n"
	s += "stopped: " + stopped as String + "\n"
	s += "scenes: " + scenes as String + "\n"
	s += "count: " + count as String + "\n"
	s += root.get_children() as String + "\n"
	# get_node("/root").print_stray_nodes()
	get_node("/root").print_tree_pretty()
	print(s)
