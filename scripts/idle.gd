extends State

@export var idle: State
@export var jump: State
@export var fall: State
@export var run: State

func enter():
	player.play_animation("idle")

func physics_update(_delta):

	var direction := Input.get_axis("ui_left", "ui_right")

	player.velocity.x = direction * player.SPEED
	
	if player.velocity.x != 0:
		state_machine.change_state(run)
	elif !player.is_on_floor() and player.velocity.y > 0:
		state_machine.change_state(fall)
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state(jump)
	else:
		state_machine.change_state(idle)
		return
	
	if direction > 0:
		player.sprite.flip_h = false
	elif direction < 0:
		player.sprite.flip_h = true
