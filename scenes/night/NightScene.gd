extends Node

## NightScene: 買い物・食事・ふれあい・就寝

@onready var status_label: Label     = $CanvasLayer/VBox/StatusLabel
@onready var result_label: Label     = $CanvasLayer/VBox/ResultLabel
@onready var main_panel: VBoxContainer  = $CanvasLayer/VBox/MainPanel
@onready var conv_panel: VBoxContainer  = $CanvasLayer/VBox/ConvPanel
@onready var touch_panel: VBoxContainer = $CanvasLayer/VBox/TouchPanel

enum Phase { MAIN, CONVERSATION, TOUCH }
var current_phase: Phase = Phase.MAIN

func _ready() -> void:
	_update_status()

func _update_status() -> void:
	status_label.text = GameState.get_status_text()

func _show_phase(phase: Phase) -> void:
	current_phase = phase
	main_panel.visible  = (phase == Phase.MAIN)
	conv_panel.visible  = (phase == Phase.CONVERSATION)
	touch_panel.visible = (phase == Phase.TOUCH)
	result_label.text   = ""

# ---- メインアクション ----

func _on_drugstore_pressed() -> void:
	if GameState.has_bought_drugstore:
		result_label.text = "今日はもう購入済みです。"
		return
	GameState.has_bought_drugstore = true
	result_label.text = "ドラッグストアで買い物した。"

func _on_yamizon_pressed() -> void:
	if GameState.has_bought_yamizon:
		result_label.text = "今日はもう購入済みです。"
		return
	GameState.has_bought_yamizon = true
	result_label.text = "Yamizonで買い物した。"

func _on_bath_pressed() -> void:
	result_label.text = "お風呂に入った。"

func _on_meal_pressed() -> void:
	GameState.affection = min(100, GameState.affection + 1)
	result_label.text = "ご飯を食べた。（好感度 +1）"
	_update_status()

func _on_talk_pressed() -> void:
	_show_phase(Phase.CONVERSATION)

func _on_touch_pressed() -> void:
	_rebuild_touch_buttons()
	_show_phase(Phase.TOUCH)

func _on_sleep_pressed() -> void:
	# 快感度 > 50 → MidnightScene
	if GameState.pleasure > 50:
		get_tree().change_scene_to_file("res://scenes/midnight/MidnightScene.tscn")
	else:
		_next_day()

# ---- 会話 ----

func _on_conv_success_pressed() -> void:
	GameState.apply_conversation_result("success")
	result_label.text = "上手く話せた！（好感度 +3）"
	_update_status()
	_show_phase(Phase.MAIN)

func _on_conv_normal_pressed() -> void:
	GameState.apply_conversation_result("normal")
	result_label.text = "普通の会話だった。（好感度 +1）"
	_update_status()
	_show_phase(Phase.MAIN)

func _on_conv_fail_pressed() -> void:
	GameState.apply_conversation_result("fail")
	result_label.text = "会話が失敗した…"
	_update_status()
	_show_phase(Phase.MAIN)

func _on_conv_back_pressed() -> void:
	_show_phase(Phase.MAIN)

# ---- ふれあい ----

func _rebuild_touch_buttons() -> void:
	for child in touch_panel.get_children():
		if child.name != "TouchBackButton":
			child.queue_free()

	var parts := GameState.get_touch_parts()
	for part in parts:
		var btn := Button.new()
		btn.text = part
		btn.pressed.connect(_on_touch_part_pressed.bind(part))
		touch_panel.add_child(btn)
		touch_panel.move_child(btn, touch_panel.get_child_count() - 2)

func _on_touch_part_pressed(part: String) -> void:
	GameState.touch_part(part)
	result_label.text = "%s を触れた。" % part
	_update_status()
	_show_phase(Phase.MAIN)

func _on_touch_back_pressed() -> void:
	_show_phase(Phase.MAIN)

# ---- 翌日へ ----

func _next_day() -> void:
	GameState.next_day()
	get_tree().change_scene_to_file("res://scenes/morning/MorningScene.tscn")
