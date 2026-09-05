extends Node

signal fruit_collected(total: int)

var fruit_count: int = 0
var life_count: int = 3
var check_position:= Vector2.ZERO


func register_fruit_collected() -> void:
	fruit_count += 1
	fruit_collected.emit(fruit_count)


func reset() -> void:
	fruit_count = 0
