extends Area2D

@export var ammo_amount := 5
@export var pop_gravity := 900.0
@export var spawn_grace_time := 0.15

@onready var sprite: Sprite2D = $Sprite2D
@onready var ground_ray: RayCast2D = $GroundRay

var collected_flag: bool = false
var is_popping: bool = false
var pop_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	set_deferred("monitoring", false)
	await get_tree().create_timer(spawn_grace_time).timeout
	set_deferred("monitoring", true)


func pop(height: float, duration: float) -> void:
	is_popping = true
	var pop_speed: float = (2.0 * height) / duration
	pop_velocity = Vector2(0, -pop_speed)


func _physics_process(delta: float) -> void:
	if not is_popping:
		return

	pop_velocity.y += pop_gravity * delta
	global_position += pop_velocity * delta

	if pop_velocity.y > 0.0 and ground_ray != null:
		ground_ray.force_raycast_update()
		if ground_ray.is_colliding():
			is_popping = false
			pop_velocity = Vector2.ZERO


func _on_body_entered(body: Node2D) -> void:
	if collected_flag:
		return

	if body.is_in_group("player") and body.has_method("equip_slingshot"):
		collected_flag = true
		set_deferred("monitoring", false)
		body.equip_slingshot(ammo_amount)
		queue_free()
