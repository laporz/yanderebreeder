extends Node

## MidnightScene: 深夜イベント（快感度・依存度上昇）

@onready var status_label: Label     = $CanvasLayer/VBox/StatusLabel
@onready var result_label: Label     = $CanvasLayer/VBox/ResultLabel
@onready var body_panel: VBoxContainer  = $CanvasLayer/VBox/BodyPanel
@onready var cum_panel: VBoxContainer   = $CanvasLayer/VBox/CumPanel
@onready var insert_panel: VBoxContainer = $CanvasLayer/VBox/InsertPanel

var inserted: bool = false
var condom_on: bool = true
var climax_count: int = 0   # 100 単位で数える

func _ready() -> void:
	_update_status()
	cum_panel.visible    = false
	insert_panel.visible = false

func _update_status() -> void:
	status_label.text = (
		"快感度: %d / 好感度: %d / 依存度: %d"
		% [GameState.pleasure, GameState.affection, GameState.dependency]
	)

# ---- 部位クリック（快感度上昇）----

func _touch_body(part: String, pleasure_gain: int, affection_gain: int = 0) -> void:
	GameState.pleasure = min(500, GameState.pleasure + pleasure_gain)
	GameState.affection = min(100, GameState.affection + affection_gain)
	result_label.text = "%s を触れた。" % part
	_update_status()
	_check_climax()

func _on_head_pressed()   -> void: _touch_body("頭",   5, 2)
func _on_chest_pressed()  -> void: _touch_body("胸",  10)
func _on_stomach_pressed()-> void: _touch_body("お腹", 8)
func _on_groin_pressed()  -> void: _touch_body("性器", 15)

# ---- 絶頂チェック ----

func _check_climax() -> void:
	var threshold := (climax_count + 1) * 100
	if GameState.pleasure >= threshold:
		climax_count += 1
		result_label.text = "絶頂！（%d回目）" % climax_count

		if climax_count == 1 and not inserted:
			# 初回絶頂 → 挿入パネル表示
			insert_panel.visible = true
			body_panel.visible   = false
		elif climax_count >= 2:
			# 2回目以降絶頂 → 射精場所選択
			_show_cum_panel()

# ---- 挿入 ----

func _on_insert_condom_pressed() -> void:
	condom_on = true
	inserted  = true
	insert_panel.visible = false
	body_panel.visible   = true
	result_label.text = "コンドームをつけて挿入した。"

func _on_insert_no_condom_pressed() -> void:
	if GameState.affection >= 100 and GameState.dependency >= 80:
		condom_on = false
		inserted  = true
		insert_panel.visible = false
		body_panel.visible   = true
		result_label.text = "コンドームなしで挿入した。"
	else:
		result_label.text = "まだその段階じゃない…（好感度100・依存度80が必要）"

func _on_insert_back_pressed() -> void:
	insert_panel.visible = false
	body_panel.visible   = true

# ---- 射精場所選択 ----

func _show_cum_panel() -> void:
	cum_panel.visible  = true
	body_panel.visible = false

func _apply_ejaculation(location: String) -> void:
	var gain: int
	match location:
		"顔":    gain = 3
		"口":    gain = 5
		"体":    gain = 2
		"腟内":
			gain = 2 if condom_on else 10
		_:       gain = 0
	GameState.dependency = min(100, GameState.dependency + gain)
	result_label.text = "%s に射精した。（依存度 +%d）" % [location, gain]
	_update_status()
	cum_panel.visible  = false
	body_panel.visible = true

func _on_cum_face_pressed()   -> void: _apply_ejaculation("顔")
func _on_cum_mouth_pressed()  -> void: _apply_ejaculation("口")
func _on_cum_body_pressed()   -> void: _apply_ejaculation("体")
func _on_cum_inside_pressed() -> void: _apply_ejaculation("腟内")

# ---- イベント終了 → 翌日 ----

func _on_end_pressed() -> void:
	GameState.next_day()
	get_tree().change_scene_to_file("res://scenes/morning/MorningScene.tscn")
