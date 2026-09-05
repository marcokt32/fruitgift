extends Button

var level_data: LevelData
var level_index: int

@onready var thumbnail_rect: TextureRect = $Thumbnail
@onready var name_label: Label = $NameLabel
@onready var lock_icon: TextureRect = $LockIcon


func setup(data: LevelData, index: int) -> void:
	level_data = data
	level_index = index

	thumbnail_rect.texture = data.thumbnail
	name_label.text = data.level_name

	var unlocked: bool = ProgressManager.is_unlocked(index)
	disabled = not unlocked
	lock_icon.visible = not unlocked
	thumbnail_rect.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.35, 0.35, 1)

	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	get_tree().change_scene_to_file(level_data.scene_path)
