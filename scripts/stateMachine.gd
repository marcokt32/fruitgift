extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State

func _ready():
	pass


func start():

	current_state = initial_state

	for child in get_children():
		child.player = get_parent()
		child.state_machine = self

	current_state.enter()


func change_state(new_state: State):

	if current_state == new_state:
		return

	if current_state:
		current_state.exit()

	current_state = new_state

	print("Estado:", current_state.name)

	current_state.enter()


func physics_update(delta):

	if current_state:
		current_state.physics_update(delta)


func update(delta):

	if current_state:
		current_state.update(delta)
