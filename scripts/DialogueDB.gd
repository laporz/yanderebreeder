extends Node

## DialogueDB — 会話データ管理 AutoLoad
## JSONを読み込み、現在の好感度ティアに合った会話データを返す

const BASE_PATH := "res://data/dialogues/"
const IMAGE_BASE := "res://assets/characters/heroine/"
const FALLBACK_OUTFIT := "normal"
const FALLBACK_EXPRESSION := "default"

# JSONキャッシュ: scene_name → 解析済みDict全体
var _cache: Dictionary = {}

# --- 外部インターフェース ---

## 現在の好感度ティアに合った会話データを返す
## 戻り値例: { "prompt": "...", "outfit": "normal", "choices": [...] }
func get_tier_data(scene_name: String) -> Dictionary:
	var data := _load_scene(scene_name)
	if data.is_empty():
		return {}
	var tier_key := str(GameState.get_affection_tier())
	var tiers: Dictionary = data.get("tiers", {})
	return tiers.get(tier_key, {})

## 画像パスを返す（フォールバック付き）
## フォールバック順: outfit/expression → outfit/default → normal/default
func resolve_image_path(outfit: String, expression: String) -> String:
	var candidates := [
		IMAGE_BASE + outfit + "/" + expression + ".png",
		IMAGE_BASE + outfit + "/" + FALLBACK_EXPRESSION + ".png",
		IMAGE_BASE + FALLBACK_OUTFIT + "/" + FALLBACK_EXPRESSION + ".png",
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""  # 画像なし（呼び出し元でハンドリング）

# --- 内部処理 ---

func _load_scene(scene_name: String) -> Dictionary:
	if _cache.has(scene_name):
		return _cache[scene_name]

	var path := BASE_PATH + scene_name + ".json"
	if not FileAccess.file_exists(path):
		push_warning("DialogueDB: ファイルが見つかりません: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueDB: ファイルを開けません: %s" % path)
		return {}

	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("DialogueDB: JSON解析失敗: %s" % path)
		return {}

	var dict: Dictionary = parsed
	_cache[scene_name] = dict
	return dict

## キャッシュをクリア（ホットリロード用）
func clear_cache() -> void:
	_cache.clear()
