extends Node

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1

# Conjunto fixo de frutas douradas do jogo (não ligadas a fase específica).
# Ajuste esse número para a quantidade real de frutas douradas do seu jogo.
const TOTAL_GOLDEN_FRUITS := 12

# -1 = nenhum slot selecionado ainda (tela de seleção deve rodar antes de qualquer coisa)
var current_slot: int = -1

var unlocked_levels: int = 1
var has_seen_intro: bool = false

# golden_fruits_collected[i] == true significa que a fruta dourada de id "i" já foi pega
var golden_fruits_collected: Array = []

# Pontuação global (nunca reseta)
var total_fruit_score: int = 0

# Soma de estrelas de todas as fases
var total_stars: int = 0

# level_records["0"] = {"fruits": int, "monsters": int, "crates": int, "stars": int}
var level_records: Dictionary = {}

# Contexto da fase em andamento
var _current_level_index: int = -1
var _current_level_totals: Dictionary = {}


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	GameEvents.fruit_collected.connect(_on_fruit_collected)
	# Não carrega nenhum save aqui: espera a tela de seleção de slot
	# chamar select_slot(n) antes de qualquer outra coisa no jogo.


# ---------------------------------------------------------------------------
# Gerenciamento de slots
# ---------------------------------------------------------------------------

func slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.save" % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


# Chame na tela de seleção quando o jogador escolher um slot (existente ou vazio).
func select_slot(slot: int) -> void:
	current_slot = slot
	if slot_exists(slot):
		_load()
	else:
		_reset_to_defaults()
		_save()


func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(slot_path(slot))
	if current_slot == slot:
		current_slot = -1


# Metadados leves para a tela de seleção, sem precisar trocar o slot ativo.
func get_slot_summary(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {"empty": true}

	var config := ConfigFile.new()
	var err := config.load(slot_path(slot))
	if err != OK:
		return {"empty": true}

	var golden_fruits: Array = config.get_value("progress", "golden_fruits_collected", [])
	golden_fruits = golden_fruits.duplicate()
	while golden_fruits.size() < TOTAL_GOLDEN_FRUITS:
		golden_fruits.append(false)
	if golden_fruits.size() > TOTAL_GOLDEN_FRUITS:
		golden_fruits.resize(TOTAL_GOLDEN_FRUITS)

	return {
		"empty": false,
		"unlocked_levels": config.get_value("progress", "unlocked_levels", 1),
		"total_stars": config.get_value("progress", "total_stars", 0),
		"total_fruit_score": config.get_value("progress", "total_fruit_score", 0),
		"golden_fruits_collected": golden_fruits,
		"updated_at": config.get_value("progress", "updated_at", 0),
	}


func _reset_to_defaults() -> void:
	unlocked_levels = 1
	level_records.clear()
	total_stars = 0
	total_fruit_score = 0
	has_seen_intro = false
	golden_fruits_collected = []
	golden_fruits_collected.resize(TOTAL_GOLDEN_FRUITS)
	golden_fruits_collected.fill(false)


# ---------------------------------------------------------------------------
# Lógica de jogo (inalterada)
# ---------------------------------------------------------------------------

# Chame no _ready() da fase, informando os totais dela
func start_level(level_index: int, totals: Dictionary) -> void:
	_current_level_index = level_index
	_current_level_totals = totals
	GameEvents.reset()


# Chame quando o jogador terminar a fase (ex: chegou na bandeira/porta final)
func finish_level() -> int:
	if _current_level_index == -1:
		return 0

	var fruits := GameEvents.fruit_count
	var monsters := GameEvents.monster_count
	var crates := GameEvents.crate_count
	var totals := _current_level_totals

	var stars := 0
	if totals.get("fruits", 0) > 0 and fruits >= totals["fruits"]:
		stars += 1
	if totals.get("monsters", 0) > 0 and monsters >= totals["monsters"]:
		stars += 1
	if totals.get("crates", 0) > 0 and crates >= totals["crates"]:
		stars += 1

	_update_level_record(_current_level_index, fruits, monsters, crates, stars)
	_save()

	return stars


func _update_level_record(level_index: int, fruits: int, monsters: int, crates: int, stars: int) -> void:
	var key := str(level_index)
	var previous: Dictionary = level_records.get(key, {"fruits": 0, "monsters": 0, "crates": 0, "stars": 0})

	level_records[key] = {
		"fruits": max(previous.get("fruits", 0), fruits),
		"monsters": max(previous.get("monsters", 0), monsters),
		"crates": max(previous.get("crates", 0), crates),
		"stars": max(previous.get("stars", 0), stars),
	}

	_recalculate_total_stars()


func _recalculate_total_stars() -> void:
	var sum := 0
	for key in level_records.keys():
		sum += level_records[key].get("stars", 0)
	total_stars = sum


# Usado pelo card da fase pra exibir o recorde salvo
func get_level_record(level_index: int) -> Dictionary:
	return level_records.get(str(level_index), {"fruits": 0, "monsters": 0, "crates": 0, "stars": 0})


func _on_fruit_collected() -> void:
	total_fruit_score += 1
	_save()


func complete_level(level_index: int) -> void:
	if level_index + 1 >= unlocked_levels:
		unlocked_levels = level_index + 2
		_save()


func is_unlocked(level_index: int) -> bool:
	return level_index < unlocked_levels


# Chame quando o jogador pegar uma fruta dourada específica no mundo, ex:
# ProgressManager.collect_golden_fruit(3)
func collect_golden_fruit(fruit_id: int) -> void:
	if fruit_id < 0 or fruit_id >= TOTAL_GOLDEN_FRUITS:
		push_warning("collect_golden_fruit: id inválido (%d)" % fruit_id)
		return
	if golden_fruits_collected[fruit_id]:
		return  # já tinha sido pega, não faz nada
	golden_fruits_collected[fruit_id] = true
	_save()


func is_golden_fruit_collected(fruit_id: int) -> bool:
	if fruit_id < 0 or fruit_id >= TOTAL_GOLDEN_FRUITS:
		return false
	return golden_fruits_collected[fruit_id]


# Cópia do array de status, pra UI usar sem risco de alterar o estado real.
func get_golden_fruits_status() -> Array:
	return golden_fruits_collected.duplicate()


func get_golden_fruits_count() -> int:
	var count := 0
	for collected in golden_fruits_collected:
		if collected:
			count += 1
	return count


func mark_intro_seen() -> void:
	if not has_seen_intro:
		has_seen_intro = true
		_save()


# Reseta o slot ATIVO (não apaga outros slots). Para apagar um slot
# específico sem ele estar carregado, use delete_slot(n).
func reset_progress() -> void:
	_reset_to_defaults()
	_save()


# ---------------------------------------------------------------------------
# Persistência (agora por slot)
# ---------------------------------------------------------------------------

func _save() -> void:
	if current_slot == -1:
		push_warning("ProgressManager: tentando salvar sem slot selecionado")
		return

	var config := ConfigFile.new()
	config.set_value("progress", "version", SAVE_VERSION)
	config.set_value("progress", "updated_at", Time.get_unix_time_from_system())
	config.set_value("progress", "unlocked_levels", unlocked_levels)
	config.set_value("progress", "has_seen_intro", has_seen_intro)
	config.set_value("progress", "total_fruit_score", total_fruit_score)
	config.set_value("progress", "total_stars", total_stars)
	config.set_value("progress", "level_records", level_records)
	config.set_value("progress", "golden_fruits_collected", golden_fruits_collected)
	config.save(slot_path(current_slot))


func _load() -> void:
	var config := ConfigFile.new()
	var err := config.load(slot_path(current_slot))
	if err == OK:
		var version: int = config.get_value("progress", "version", 0)
		unlocked_levels = config.get_value("progress", "unlocked_levels", 1)
		has_seen_intro = config.get_value("progress", "has_seen_intro", false)
		total_fruit_score = config.get_value("progress", "total_fruit_score", 0)
		total_stars = config.get_value("progress", "total_stars", 0)
		level_records = config.get_value("progress", "level_records", {})
		golden_fruits_collected = config.get_value("progress", "golden_fruits_collected", [])
		_normalize_golden_fruits_size()
		if version < SAVE_VERSION:
			_migrate(version)


# Garante que o array sempre tenha TOTAL_GOLDEN_FRUITS elementos, mesmo se
# esse número mudar entre versões do jogo (ex: você adicionou mais frutas).
func _normalize_golden_fruits_size() -> void:
	while golden_fruits_collected.size() < TOTAL_GOLDEN_FRUITS:
		golden_fruits_collected.append(false)
	if golden_fruits_collected.size() > TOTAL_GOLDEN_FRUITS:
		golden_fruits_collected.resize(TOTAL_GOLDEN_FRUITS)


# Aplique transformações incrementais aqui conforme o formato do save evolui.
# Exemplo (quando a versão 2 existir):
# func _migrate(from_version: int) -> void:
#     if from_version < 2:
#         ... transforma dados antigos ...
#     _save()
func _migrate(_from_version: int) -> void:
	pass
