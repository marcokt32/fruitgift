extends Control

# Caminho da cena de seleção de fases, destino após intro (ou direto, se já viu).
@export var level_select_path: String = ""

# Caminho da cena de intro, mostrada só quando o slot ainda não a viu.
@export var intro_scene_path: String = ""

# Ícones do badge de fruta dourada. Troque pelos caminhos reais dos seus assets.
const GOLDEN_FRUIT_ICON_COLLECTED := preload("res://assets/Menu/Icons/golden_fruit_badge.png")
const GOLDEN_FRUIT_ICON_LOCKED := preload("res://assets/Menu/Icons/golden_fruit_badge_empty.png")

const BADGE_SIZE := Vector2(25, 25)

var _slot_pending_delete: int = -1


func _ready() -> void:
	var ok_button: Button = %ConfirmDeleteDialog.get_ok_button()
	ok_button.text = "BTN_CONFIRM"
	ok_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS

	var cancel_button: Button = %ConfirmDeleteDialog.get_cancel_button()
	cancel_button.text = "BTN_CANCEL"
	cancel_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	
	
	_refresh_all_slots()

	%PlayButton1.pressed.connect(_on_slot_pressed.bind(0))
	%PlayButton2.pressed.connect(_on_slot_pressed.bind(1))
	%PlayButton3.pressed.connect(_on_slot_pressed.bind(2))

	%DeleteButton1.pressed.connect(_on_delete_pressed.bind(0))
	%DeleteButton2.pressed.connect(_on_delete_pressed.bind(1))
	%DeleteButton3.pressed.connect(_on_delete_pressed.bind(2))

	%ConfirmDeleteDialog.confirmed.connect(_on_delete_confirmed)
	%ConfirmDeleteDialog.visibility_changed.connect(_on_confirm_dialog_visibility_changed)

	# Garante que o overlay começa escondido, mesmo que tenha ficado
	# visível por engano no editor.
	%ConfirmOverlay.visible = false


func _refresh_all_slots() -> void:
	_refresh_slot(0, %LevelsLabel1, %StarsLabel1, %FruitLabel1, %GoldenGrid1, %PlayButton1, %DeleteButton1)
	_refresh_slot(1, %LevelsLabel2, %StarsLabel2, %FruitLabel2, %GoldenGrid2, %PlayButton2, %DeleteButton2)
	_refresh_slot(2, %LevelsLabel3, %StarsLabel3, %FruitLabel3, %GoldenGrid3, %PlayButton3, %DeleteButton3)


func _refresh_slot(
	slot: int,
	levels_label: Label,
	stars_label: Label,
	fruit_label: Label,
	grid: GridContainer,
	play_button: Button,
	delete_button: Button
) -> void:
	var summary := ProgressManager.get_slot_summary(slot)

	if summary.get("empty", true):
		levels_label.text = tr("MSG_EMPTY_SLOT") % (slot + 1)
		stars_label.text = ""
		fruit_label.text = ""
		play_button.text = "BTN_NEW_GAME"
		delete_button.disabled = true
		delete_button.visible = false
		grid.visible = false
		return

	var levels: int = summary.get("unlocked_levels", 1)
	var stars: int = summary.get("total_stars", 0)
	var fruit_score: int = summary.get("total_fruit_score", 0)

	# "Fases avançadas" = fases já desbloqueadas menos a atual em progresso.
	var levels_advanced: int = max(levels - 1, 0)

	levels_label.text = "%s: %d" % [tr("HUD_LEVEL"), levels_advanced]
	stars_label.text = "%s: %d" % [tr("HUD_STARS"), stars]
	fruit_label.text = "%s: %d" % [tr("HUD_FRUITS"), fruit_score]

	play_button.text = "BTN_RESUME"
	delete_button.disabled = false
	delete_button.visible = true

	_populate_golden_grid(grid, summary.get("golden_fruits_collected", []))


func _populate_golden_grid(grid: GridContainer, golden_fruits: Array) -> void:
	grid.visible = true
	# Limpa badges antigos (caso a tela seja atualizada mais de uma vez)
	for child in grid.get_children():
		child.queue_free()

	for i in golden_fruits.size():
		var collected: bool = golden_fruits[i]
		var badge := TextureRect.new()
		badge.texture = GOLDEN_FRUIT_ICON_COLLECTED if collected else GOLDEN_FRUIT_ICON_LOCKED
		badge.custom_minimum_size = BADGE_SIZE
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.tooltip_text = "Fruta dourada %d" % (i + 1) if collected else "???"
		grid.add_child(badge)


func _on_slot_pressed(slot: int) -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	ProgressManager.select_slot(slot)
	if not ProgressManager.has_seen_intro:
		get_tree().change_scene_to_file(intro_scene_path)
	else:
		get_tree().change_scene_to_file(level_select_path)


func _on_delete_pressed(slot: int) -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	_slot_pending_delete = slot
	%ConfirmDeleteDialog.dialog_text = tr("MSG_DELETE_SLOT") % (slot + 1)
	%ConfirmOverlay.visible = true
	%ConfirmDeleteDialog.popup_centered()


func _on_delete_confirmed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	if _slot_pending_delete == -1:
		return
	ProgressManager.delete_slot(_slot_pending_delete)
	_slot_pending_delete = -1
	_refresh_all_slots()


# Chamado sempre que o Window do dialog abre OU fecha (confirmar, cancelar,
# clicar fora, apertar ES"res://scenes/main_menu.tscn"C — todos os caminhos passam por aqui).
func _on_confirm_dialog_visibility_changed() -> void:
	%ConfirmOverlay.visible = %ConfirmDeleteDialog.visible

func _on_back_button_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
