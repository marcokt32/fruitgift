extends State
@export var idle: State
@export var run: State
@export var jump: State
@export var fall: State

func enter():
	player.play_animation("fall")

func physics_update(_delta):
	var direction := Input.get_axis("ui_left", "ui_right")
	player.velocity.x = direction * player.SPEED
	if direction > 0:
		player.sprite.flip_h = false
	elif direction < 0:
		player.sprite.flip_h = true

	if player.is_on_floor():
		if direction == 0:
			state_machine.change_state(idle)
		else:
			state_machine.change_state(run)
