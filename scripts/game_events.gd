extends Node

signal fruit_collected
signal monster_defeated
signal crate_collected
signal player_respawned
signal boss_stun_shake
signal player_damaged

var fruit_count: int = 0
var monster_count: int = 0
var crate_count: int = 0
var life_count: int = 3
var check_position := Vector2.ZERO
var ammo: int = 0


func register_fruit_collected() -> void:
	fruit_count += 1


func register_monster_defeated() -> void:
	monster_count += 1
	monster_defeated.emit()


func register_crate_collected() -> void:
	crate_count += 1
	crate_collected.emit()


func reset() -> void:
	fruit_count = 0
	monster_count = 0
	crate_count = 0
