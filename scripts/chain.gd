@tool
extends Node2D

@export var point_a_path: NodePath
@export var point_b_path: NodePath
@export var link_texture: Texture2D
@export var link_spacing := 16.0
@export var link_scale := 1.0

@export var regenerate := false:
	set(value):
		_generate_chain()


func _ready() -> void:
	_generate_chain()


func _generate_chain() -> void:
	if point_a_path.is_empty() or point_b_path.is_empty() or link_texture == null:
		return

	var node_a := get_node_or_null(point_a_path)
	var node_b := get_node_or_null(point_b_path)

	if node_a == null or node_b == null:
		return

	# limpa elos antigos antes de gerar de novo (evita duplicar ao reexecutar)
	for child in get_children():
		child.queue_free()

	var point_a: Vector2 = to_local(node_a.global_position)
	var point_b: Vector2 = to_local(node_b.global_position)

	var path_vector: Vector2 = point_b - point_a
	var distance: float = path_vector.length()
	var direction: Vector2 = path_vector.normalized()

	if distance <= 0.0:
		return

	var link_count: int = int(distance / link_spacing)
	var link_size: Vector2 = link_texture.get_size() * link_scale

	for i in range(link_count + 1):
		var link := TextureRect.new()
		link.texture = link_texture
		link.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		link.stretch_mode = TextureRect.STRETCH_SCALE
		link.size = link_size
		link.pivot_offset = link_size / 2.0
		link.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var link_pos: Vector2 = point_a + direction * (i * link_spacing)
		link.position = link_pos - link_size / 2.0

		add_child(link)
		if Engine.is_editor_hint():
			link.owner = get_tree().edited_scene_rootextends
