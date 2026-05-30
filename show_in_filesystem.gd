@tool
extends EditorPlugin

var _base_control: Control


func _enter_tree() -> void:
	_base_control = get_editor_interface().get_base_control()


func _exit_tree() -> void:
	pass


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_MIDDLE or not event.pressed:
		return

	var hovered: Control = _base_control.get_viewport().gui_get_hovered_control()
	if not hovered:
		return

	if _try_scene_tree(hovered):
		get_viewport().set_input_as_handled()
		return

	if _try_inspector(hovered):
		get_viewport().set_input_as_handled()
		return


func _try_scene_tree(hovered: Control) -> bool:
	var tree: Tree = _find_parent_of_class(hovered, "Tree") as Tree
	if not tree:
		return false

	# Make sure this Tree belongs to the SceneTreeEditor.
	if not _has_parent_of_class(tree, "SceneTreeEditor"):
		return false

	var local_pos := tree.get_local_mouse_position()
	var item := tree.get_item_at_position(local_pos)
	if not item:
		return false

	var meta = item.get_metadata(0)
	if not meta is NodePath:
		return false

	var node_path: NodePath = meta
	var root := get_editor_interface().get_edited_scene_root()
	if not root:
		return false

	var node := root.get_node_or_null(node_path)
	if not node:
		return false

	var scene_path: String = node.scene_file_path
	if scene_path.is_empty():
		return false

	get_editor_interface().get_file_system_dock().navigate_to_path(scene_path)
	return true


func _try_inspector(hovered: Control) -> bool:
	if not _has_parent_of_class(hovered, "EditorInspector"):
		return false

	# Prefer EditorResourcePicker because it gives the resource directly.
	var picker = _find_parent_of_class(hovered, "EditorResourcePicker")
	if picker:
		var resource = picker.get_edited_resource()
		if resource and resource is Resource:
			var path: String = resource.resource_path
			if not path.is_empty():
				get_editor_interface().get_file_system_dock().navigate_to_path(path)
				return true
		return false

	# Fall back to EditorProperty (covers sub-inspectors / collapsed resources).
	var prop = _find_parent_of_class(hovered, "EditorProperty")
	if prop:
		var obj = prop.get_edited_object()
		var prop_name = prop.get_edited_property()
		if obj and prop_name:
			var value = obj.get(prop_name)
			if value is Resource:
				var path: String = value.resource_path
				if not path.is_empty():
					get_editor_interface().get_file_system_dock().navigate_to_path(path)
					return true
		return false

	return false


func _find_parent_of_class(node: Node, class_name_str: String) -> Node:
	var current := node
	while current:
		if current.is_class(class_name_str):
			return current
		current = current.get_parent()
	return null


func _has_parent_of_class(node: Node, class_name_str: String) -> bool:
	return _find_parent_of_class(node, class_name_str) != null
