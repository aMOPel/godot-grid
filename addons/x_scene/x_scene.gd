# __robust, high level interface__ for manipulating and indexing scenes below a
# given `Node`.
class_name XScene

# TODO: consider doing it all with fsm
# TODO: sort out when to assert, print_debug, push_error
# TODO: make option for auto_sync to add keys by count or by node.name

# warnings-disable

extends Node

# enum with the scene state \
# `ACTIVE` = 0 uses `add_child()` \
# `HIDDEN` = 1 uses `.hide()` \
# `STOPPED` = 2 uses `remove_child()` \
# `FREE` = 3 uses `.free()`
enum { ACTIVE, HIDDEN, STOPPED, FREE }

# Dictionary that holds all indexed scenes and their state \
# has either `count` or String as keys \
# Eg. {1:{scene:[Node2D:1235], state:0}, abra:{scene:[Node2D:1239], state:1}}
var scenes := {} setget _dont_set, _get_scenes

# Array of keys of active scenes
var active := [] setget _dont_set, _get_active

# Array of keys of hidden scenes
var hidden := [] setget _dont_set, _get_hidden

# Array of keys of stopped scenes
var stopped := [] setget _dont_set, _get_stopped

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
# `method_change` = ACTIVE, \
# `count_start` = 1 | This is only applied when passing it to the `_init()` of XScene
var defaults: Dictionary setget _set_defaults

# constant original default values, used for comparison in `_set_defaults()` and to reset
const _original_defaults := {
	deferred = false,
	recursive_owner = false,
	method_add = ACTIVE,
	method_remove = FREE,
	method_change = ACTIVE,
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
# you can also pass partial dictionaries \
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
	assert(
		false,
		"XScene: do not set any property, except defaults in XScene manually"
	)


# setting defaults Dictionary
func _set_defaults(d: Dictionary) -> void:
	for k in d:
		if _check_type(k, d[k]):
			defaults[k] = d[k]


func _get_active() -> Array:
	_check_scenes(ACTIVE)
	return active


func _get_hidden() -> Array:
	_check_scenes(HIDDEN)
	return hidden


func _get_stopped() -> Array:
	_check_scenes(STOPPED)
	return stopped


func _get_scenes() -> Dictionary:
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


# returns the `data` Dictionary in of `key` in `scenes`
# the `data` Dictionary is not used by this plugin, but can be used to associate data with a scene
func d(key) -> Dictionary:
	if _check_scene(key):
		return scenes[key].data
	else:
		print_debug(
			"XScene.d: returning empty dictionary, key invalid " + key as String
		)
		return {}


# do multiple "x"ess"s", get Array of Nodes based on `method` \
# if null, return all scenes(nodes) from `scenes` \
# if method specified, return only the scenes(nodes) in the respective state \
# `method`: null / `ACTIVE` / `HIDDEN` / `STOPPED` | default: null
func xs(method = null) -> Array:
	if method != null:
		_check_type('method_add', method)
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


# uses PackedScene.instance() or Node.duplicate() or Object.new() on s
func to_node(s) -> Node:
	var n: Node
	if s is PackedScene:
		n = s.instance()
	elif s is Node:
		n = s.duplicate()
	elif s is Object:
		n = s.new()
		assert(
			n is Node,
			"XScene.to_node: if s is Object, s.new() has to be Node " + s.to_string()
		)
	else:
		assert(
			false,
			"XScene.to_node: s must be PackedScene or Node or Object" + s.to_string()
		)
	return n


# sets undefined values to their respective values in `defaults`
func parse_args(args: Dictionary) -> Dictionary:
	if 'already_parsed' in args:
		return args
	var d := {
		method_change = defaults.method_change,
		method_add = defaults.method_add,
		method_remove = defaults.method_remove,
		deferred = defaults.deferred,
		recursive_owner = defaults.recursive_owner,
	}

	for k in args:
		if _check_type(k, args[k]):
			d[k] = args[k]
	d.already_parsed = true
	return d


# change state of `key` to any other state \
# a wrapper around `show_scene()` and `remove_scene()` \
# `args` takes `method_change` and `deferred` keys  \
# these values default to their respective values in `defaults`
func change_scene(key, args: Dictionary) -> void:
	if not _check_scene(key):
		push_error("XScene.change_scene: key invalid " + key as String)
		return

	var d: Dictionary
	d = parse_args(args)

	var s = scenes[key]

	if s.state == d.method_change:
		print_debug(
			(
				"XScene.change_scene: method_change is same as current state, aborting "
				+ s.to_string()
			)
		)
		return

	if s.state != ACTIVE and d.method_change == ACTIVE:
		show_scene(key, args)
	else:
		args.method_remove = args.method_change
		remove_scene(key, args)


# add a scene to the tree below `root` and to `scenes` \
# `ACTIVE` uses `add_child()` \
# `HIDDEN` uses `add_child()` and `.hide()` \
# `STOPPED` only adds to `scenes` not to the tree \
# `scene`: Node / PackagedScene \
# `key`: `count` / String | default: `count` | key in `scenes` \
# `args.method_add`: `ACTIVE` / `HIDDEN` / `STOPPED` | default: `ACTIVE` \
# `args.deferred`: bool | default: false | whether to use call_deferred() for tree
# changes \
# `args.recursive_owner`: bool | default: false | wether to recursively for all
# children of `scene` set the owner to `root`, this is useful for `pack_root()`
func add_scene(new_scene, key = count, args := {}) -> void:
	_check_type('key', key)
	assert(
		! (key in scenes),
		"XScene.add_scene: key already exists " + key as String
	)

	var d: Dictionary
	d = parse_args(args)

	var s: Node = to_node(new_scene)

	if d.method_add != STOPPED:
		_adding_scene = true
		if d.deferred:
			root.call_deferred("add_child", s)
			# count must be incremented before yield
			# TODO: can this condition come before the surrounding if/else?
			if key == count:
				count += 1
			yield(s, "tree_entered")
		else:
			root.add_child(s)
			if key == count:
				count += 1
		_adding_scene = false

		if d.recursive_owner:
			s.propagate_call("set_owner", [root])
		else:
			s.owner = root

		if d.method_add == HIDDEN:
			if not s is CanvasItem:
				print_debug(
					(
						"XScene.add_scene: new_scene must inherit from CanvasItem to be hidden "
						+ s.to_string()
					)
				)
			else:
				s.hide()

	scenes[key] = {scene = s, state = d.method_add, alternatives = {}, data = {}}


func switch_alternative(alternative_key_to, alternative_key_from, key = count, args:= {}) -> void:
	var s = scenes[key]

	var d: Dictionary
	d = parse_args(args)

	if d.method_remove == FREE:
		d.method_remove = STOPPED
	remove_scene(key, d)
	s.alternatives[alternative_key_to] = s.scene

	s.scene = s.alternatives[alternative_key_from]
	show_scene(key, d)


func add_alternative(scene, alternative_key, key = count, args:={}) -> void:
	var s = scenes[key]

	if not alternative_key in s.alternatives:
		s.alternatives[alternative_key] = to_node(scene)




# make `key` visible, and update `scenes` \
# it uses `_check_scene` to verify that the Node is still valid \
# if key is `HIDDEN` it uses `.show()` \
# if key is `STOPPED` it uses `add_child()` and `.show()` \
# `key` : int / String | default: `count` | key in `scenes` \
# `args.deferred` : bool | default: false | whether to use `call_deferred()` for tree
# changes
func show_scene(key = count, args := {}) -> void:
	_check_type('key', key)
	if not _check_scene(key):
		push_error("XScene.show_scene: key invalid " + key as String)
		return

	var d: Dictionary
	d = parse_args(args)

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
					"XScene.show_scene: scene must inherit from CanvasItem to be hidden ",
					s
				)
				return
			s.scene.show()
		STOPPED:
			_adding_scene = true
			if d.deferred:
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
# `args.method_remove`: `HIDDEN` / `STOPPED` / `FREE` | default: `FREE` \
# `args.deferred`: bool | default: false | whether to use `call_deferred()` or
# `queue_free()` for tree changes
func remove_scene(key = count, args := {}) -> void:
	_check_type('key', key)
	if not _check_scene(key):
		push_error("XScene.remove_scene: key invalid " + key as String)
		return

	var d: Dictionary
	d = parse_args(args)

	var s = scenes[key]

	match d.method_remove:
		HIDDEN:
			if not s.scene is CanvasItem:
				print_debug(
					"XScene.remove_scene: scene must inherit from CanvasItem to be hidden ",
					s
				)
				return

			if s.state == STOPPED:
				root.add_child(s.scene)
			s.scene.hide()
			s.state = HIDDEN
		STOPPED:
			if s.state != STOPPED:
				if s.scene is CanvasItem and s.state == HIDDEN:
					s.scene.show()
				_removing_scene = true
				if d.deferred:
					root.call_deferred("remove_child", s.scene)
					s.state = STOPPED
					yield(s.scene, "tree_exited")
				else:
					root.remove_child(s.scene)
					s.state = STOPPED
				_removing_scene = false
				if 'to_alternative' in d:
					s.alternatives[d.to_alternative] = s.scene
		FREE:
			_removing_scene = true
			if d.deferred:
				s.scene.queue_free()
			else:
				s.scene.free()
			_removing_scene = false
			scenes.erase(key)


# use `show_scene(key_to, args)`
# and `remove_scene(key_from, args)` \
# `key_from`: int / String | default: null | use `remove_scene()` with this key, \
# if null, the last active scene will be used, mind that the order of `active`
# only depends on the order of `scenes`
# hiding/stopping and then showing scenes won't change the order \
# see `show_scene()` and `remove_scene()` for other parameters
func x_scene(key_to, key_from = null, args := {}) -> void:
	if key_from == null:
		key_from = self.active[-1]
	show_scene(key_to, args)
	remove_scene(key_from, args)


# use `add_scene(scene_to, key_to, args)`
# and `remove_scene(key_from, args)`
# `key_to`: `count` / String | default: `count` | use `add_scene()` with this key \
# `key_from`: int / String | default: null | use `remove_scene()` with this key, \
# if null, the last active scene will be used, mind that the order of `active`
# only depends on the order of `scenes`
# hiding/stopping and then showing scenes won't change the order \
# see `add_scene()` and `remove_scene()` for other parameters
func x_add_scene(scene_to, key_to = count, key_from = null, args := {}) -> void:
	if key_from == null:
		key_from = self.active[-1]
	remove_scene(key_from, args)
	add_scene(scene_to, key_to, args)


# swap the Dictionaries in `scenes` for these two keys \
# `key_from`: int / String | default: null | use `remove_scene()` with this key, \
# if null, the last active scene will be used, mind that the order of `active`
# only depends on the order of `scenes`
# hiding/stopping and then showing scenes won't change the order 
func swap_scene(key_to = count, key_from = null) -> void:
	if key_from == null:
		key_from = self.active[-1]
	var temp: Dictionary
	temp = scenes[key_to]
	scenes[key_to] = scenes[key_from]
	scenes[key_from] = temp


# adds multiple scenes with `add_scene()` \
# `scenes` : Array<Node or PackedScene> \
# `keys` : count / Array<String> | default: count | if it isn't count the Array has to be the same size as `scenes` \
# see `add_scene()` for other parameters
func add_scenes(new_scenes: Array, keys = count, args := {}) -> void:
	if keys is int:
		assert(
			keys == count,
			(
				"XScene.add_scenes: key must be array if it isn't count "
				+ keys as String
			)
		)
		for s in new_scenes:
			add_scene(s, count, args)
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
			add_scene(new_scenes[i], keys[i], args)


# show multiple scenes with `show_scene()` \
# `keys` : Array<String and/or int> \
# see `show_scene()` for other parameters
func show_scenes(keys: Array, args := {}) -> void:
	for k in keys:
		show_scene(k, args)


# removes multiple scenes with `remove_scene()` \
# `keys` : Array<String and/or int> \
# see `remove_scene()` for other parameters
func remove_scenes(keys: Array, args := {}) -> void:
	for k in keys:
		remove_scene(k, args)


# pack `root` into `filepath` using `PackedScene.pack()` and `ResourceSaver.save()` \
# this works together with the `recursive_owner` parameter of `add_scene()` \
# mind that the `recursive_owner` parameter is only necessary for scenes
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


# `arg` is possible key in `args`
# `value` is its value
# this checks if the `value` is of the right type and is valid for the key `arg` in `args`
func _check_type(arg: String, value) -> bool:
	match arg:
		'key':
			assert(
				value is int or value is String,
				(
					"XScene._check_type: key must be int or String "
					+ value as String
				)
			)
		'method_add':
			assert(
				value is int and ACTIVE <= value and value <= STOPPED,
				(
					"XScene._check_type: invalid method_add value "
					+ value as String
				)
			)
		'method_remove':
			assert(
				value is int and HIDDEN <= value and value <= FREE,
				(
					"XScene._check_type: invalid method_remove value "
					+ value as String
				)
			)
		'method_change':
			assert(
				value is int and ACTIVE <= value and value <= FREE,
				(
					"XScene._check_type: invalid method_change value "
					+ value as String
				)
			)
		'deferred':
			assert(
				value is bool,
				(
					"XScene._check_type: deferred needs to be bool "
					+ value as String
				)
			)
		'recursive_owner':
			assert(
				value is bool,
				(
					"XScene._check_type: recursive_owner needs to be bool "
					+ value as String
				)
			)
		'to_alternative':
			assert(
				value is int or value is String,
				(
					"XScene._check_type: to_alternative needs to be int or String "
					+ value as String
				)
			)
		'count_start':
			assert(
				value is int and value >= 0,
				(
					"XScene._check_type: count_start must be >= 0 "
					+ value as String
				)
			)
		_:
			print_debug('XScene._check_type: unrecognized key ' + arg as String)
			return false
	return true
