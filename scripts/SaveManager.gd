extends Node

## SaveManager — セーブ＆ロード管理 AutoLoad
## スロット: autosave / save1 / save2 / save3

const SAVE_DIR   := "user://saves/"
const SLOT_NAMES := ["autosave", "save1", "save2", "save3"]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# ------------------------------------------------------------------ #
#  外部インターフェース
# ------------------------------------------------------------------ #

## ゲーム状態をスロットに保存
## scene_name: 保存時の現在シーン ("morning" / "night")
func save_game(slot: String, scene_name: String) -> void:
	var data := {
		"slot":                 slot,
		"scene":                scene_name,
		"day":                  GameState.day,
		"affection":            GameState.affection,
		"lust":                 GameState.lust,
		"dependency":           GameState.dependency,
		"pleasure":             GameState.pleasure,
		"has_bought_drugstore": GameState.has_bought_drugstore,
		"has_bought_yamizon":   GameState.has_bought_yamizon,
		"inventory":            GameState.inventory,
		"timestamp":            Time.get_datetime_string_from_system(),
	}
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 書き込み失敗 %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	print("SaveManager: 保存完了 [%s] 第%d日目" % [slot, GameState.day])

## オートセーブ（翌日へ進む直前に呼ぶ）
func auto_save(scene_name: String) -> void:
	save_game("autosave", scene_name)

## スロットのデータを読み込んで GameState に適用
## 成功: true / スロットが空または壊れている: false
func load_game(slot: String) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_error("SaveManager: JSON解析失敗 %s" % path)
		return false
	var data: Dictionary = parsed
	_apply_to_game_state(data)
	print("SaveManager: ロード完了 [%s] 第%d日目" % [slot, GameState.day])
	return true

## スロット情報を返す（タイトル画面の表示用）
## { exists, slot, day, scene, timestamp, label }
func get_slot_info(slot: String) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return { "exists": false, "slot": slot, "label": "（空）" }
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return { "exists": false, "slot": slot, "label": "（読み込みエラー）" }
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		return { "exists": false, "slot": slot, "label": "（データ破損）" }
	var data: Dictionary = parsed
	var scene_jp: String = _scene_label(data.get("scene", ""))
	var label: String = "第%d日目  %s  [%s]" % [
		int(data.get("day", 0)),
		scene_jp,
		str(data.get("timestamp", "")).substr(0, 16)
	]
	return {
		"exists":    true,
		"slot":      slot,
		"day":       int(data.get("day", 0)),
		"scene":     data.get("scene", "morning"),
		"timestamp": data.get("timestamp", ""),
		"label":     label,
	}

## ロード後に遷移すべきシーンパスを返す
func get_scene_path(slot: String) -> String:
	var info := get_slot_info(slot)
	if not info.get("exists", false):
		return "res://scenes/morning/MorningScene.tscn"
	match info.get("scene", "morning"):
		"night":    return "res://scenes/night/NightScene.tscn"
		_:          return "res://scenes/morning/MorningScene.tscn"

## いずれかのスロットにセーブデータが存在するか
func any_save_exists() -> bool:
	for slot in SLOT_NAMES:
		if FileAccess.file_exists(_slot_path(slot)):
			return true
	return false

# ------------------------------------------------------------------ #
#  内部処理
# ------------------------------------------------------------------ #

func _slot_path(slot: String) -> String:
	return SAVE_DIR + slot + ".json"

func _apply_to_game_state(data: Dictionary) -> void:
	GameState.day                  = int(data.get("day",       1))
	GameState.affection            = int(data.get("affection", 0))
	GameState.lust                 = int(data.get("lust",      0))
	GameState.dependency           = int(data.get("dependency",0))
	GameState.pleasure             = int(data.get("pleasure",  0))
	GameState.has_bought_drugstore = bool(data.get("has_bought_drugstore", false))
	GameState.has_bought_yamizon   = bool(data.get("has_bought_yamizon",   false))
	var inv: Variant = data.get("inventory", [])
	GameState.inventory = (inv as Array).map(func(x): return str(x))

func _scene_label(scene: String) -> String:
	match scene:
		"morning": return "朝"
		"night":   return "夜"
		_:         return scene
