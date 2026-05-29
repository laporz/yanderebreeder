extends Node

## ゲーム全体のステータスを管理するシングルトン

# --- ヒロインステータス ---
var affection: int = 0     # 好感度    0-100
var lust: int = 0          # 淫乱度    0-100
var dependency: int = 0    # 依存度    0-100
var pleasure: int = 0      # 快感度    0-500

# --- ゲーム進行 ---
var day: int = 1
var has_bought_drugstore: bool = false
var has_bought_yamizon: bool = false
var inventory: Array[String] = []

# --- 好感度ティア取得 ---
func get_affection_tier() -> int:
	if affection <= 19: return 0
	elif affection <= 39: return 1
	elif affection <= 59: return 2
	elif affection <= 79: return 3
	else: return 4

func get_affection_label() -> String:
	match get_affection_tier():
		0: return "初対面"
		1: return "慣れてきた"
		2: return "仲良し"
		3: return "気になる人"
		_: return "ラブラブ"

# --- 好感度帯で触れる部位リスト ---
func get_touch_parts() -> Array[String]:
	var tier := get_affection_tier()
	match tier:
		0: return ["頭", "手"]
		1: return ["頭", "顔", "手"]
		2: return ["頭", "顔", "手", "胸"]
		3: return ["頭", "顔", "口", "手", "胸", "お腹"]
		_: return ["頭", "顔", "口", "手", "胸", "お腹", "性器"]

# --- 部位タッチ処理 ---
func touch_part(part: String) -> void:
	match part:
		"頭":
			affection = min(100, affection + 3)
		"顔":
			affection = min(100, affection + 1)
			lust     = min(100, lust + 1)
		"口":
			affection = min(100, affection + 1)
			lust     = min(100, lust + 2)
		"手":
			affection = min(100, affection + 2)
			lust     = min(100, lust + 1)
		"胸":
			lust = min(100, lust + 2)
		"お腹":
			lust = min(100, lust + 2)
		"性器":
			lust = min(100, lust + 3)

# --- 会話結果処理 ---
func apply_conversation_result(result: String) -> void:
	match result:
		"success": affection = min(100, affection + 3)
		"normal":  affection = min(100, affection + 1)
		"fail":    pass

# --- 翌日の快感度初期値（淫乱度で決まる）---
func get_initial_pleasure() -> int:
	if lust <= 20: return 0
	elif lust <= 40: return 20
	elif lust <= 60: return 40
	elif lust <= 80: return 60
	else: return 80

# --- 翌日処理 ---
func next_day() -> void:
	day += 1
	has_bought_drugstore = false
	has_bought_yamizon   = false
	pleasure = get_initial_pleasure()

# --- ステータス文字列（デバッグ・表示用）---
func get_status_text() -> String:
	return (
		"第%d日目\n好感度: %d / 淫乱度: %d / 依存度: %d / 快感度: %d\n状態: %s"
		% [day, affection, lust, dependency, pleasure, get_affection_label()]
	)
