extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Loop through all child nodes to find states
	for child in get_children():
		if child is State:
			# Save states in dictionary using node name
			states[child.name.to_lower()] = child
			child.transitioned.connect(on_child_transition)
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(state: State, new_state_name: String) -> void:
	# Ignore if background state tries to transition while not active
	if state != current_state:
		return
		
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
		
	# Clean up old state, boot up new state
	if current_state:
		current_state.exit()
		
	new_state.enter()
	current_state = new_state

func force_transition(new_state_name: String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	if !new_state or new_state == current_state:
		return
		
	if current_state:
		current_state.exit()
		
	new_state.enter()
	current_state = new_state
