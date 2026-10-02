extends Resource
class_name LevelData

@export var level_index: int = 0
@export var level_name: String = ""
@export var scene_path: String = ""
@export var thumbnail: CompressedTexture2D

@export_group("Objetivos da fase")
@export var total_fruits: int = 0
@export var total_monsters: int = 0
@export_range(3, 3) var total_coins: int = 3
