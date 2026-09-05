extends Area2D

@export var world_check_ray_length := 4.0
@export var world_collision_mask: int = 2  # ajuste pro bitmask da sua layer "world"

var is_active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true


func _physics_process(delta: float) -> void:
	var touching_world: bool = _is_touching_world()
	if touching_world and not is_active:
		_activate()
	elif not touching_world and is_active:
		_deactivate()


func _is_touching_world() -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()

	var shape_node: CollisionShape2D = $CollisionShape2D
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = world_collision_mask
	query.exclude = [self]

	var result := space_state.intersect_shape(query, 1)
	return result.size() > 0


func _activate() -> void:
	is_active = true
	# checa quem JÁ está dentro no momento exato da ativação
	for body in get_overlapping_bodies():
		_try_kill(body)


func _deactivate() -> void:
	is_active = false


func _on_body_entered(body: Node2D) -> void:
	if is_active:
		_try_kill(body)


func _try_kill(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("_die"):
		body._die()
