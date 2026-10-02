extends OptionButton

const ICON_SIZE := Vector2(20, 20)

const ICON_PT := preload("res://assets/Menu/Icons/BrasilIcon 150x150.png")
const ICON_EN := preload("res://assets/Menu/Icons/EUAIcon 150x150.png")
const ICON_ES := preload("res://assets/Menu/Icons/Espanha Icon 150x150.png")


func _ready() -> void:
	add_item("Português")
	set_item_metadata(0, "pt_BR")
	set_item_icon(0, _resize_icon(ICON_PT))

	add_item("English")
	set_item_metadata(1, "en")
	set_item_icon(1, _resize_icon(ICON_EN))

	add_item("Español")
	set_item_metadata(2, "es")
	set_item_icon(2, _resize_icon(ICON_ES))

	_select_current_language()

	item_selected.connect(_on_language_selected)


func _resize_icon(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	image.resize(int(ICON_SIZE.x), int(ICON_SIZE.y), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _select_current_language() -> void:
	var current_language: String = SettingsManager.get_language()

	for i in range(item_count):
		if get_item_metadata(i) == current_language:
			select(i)
			return


func _on_language_selected(index: int) -> void:
	var language: String = get_item_metadata(index)
	SettingsManager.set_language(language)
