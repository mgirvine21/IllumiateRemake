extends Node

const ACTIONS = [
	&"jump",
	&"left",
	&"right",
]

@onready var _player_actions = _setup_actions()

func _setup_actions() -> Dictionary[Global.Player, Dictionary]:
	var player_actions: Dictionary[Global.Player, Dictionary] = {
			Global.Player.ONE: {},
		}

	for action: StringName in ACTIONS:
		var p1: StringName = "player_" + action
		player_actions[Global.Player.ONE][action] = p1
		var deadzone := InputMap.action_get_deadzone(action)
		InputMap.add_action(p1, deadzone)

		for event: InputEvent in InputMap.action_get_events(action):
			InputMap.action_add_event(p1, event)

	return player_actions

func lookup(player: Global.Player, action: StringName) -> StringName:
	return _player_actions[player][action]
