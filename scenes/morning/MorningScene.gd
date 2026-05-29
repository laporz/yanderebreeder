extends Node

## MorningScene: 会話・ふれあい・ステータス確認

enum Phase { MAIN, CONVERSATION, TOUCH, STATUS }

var current_phase: Phase = Phase.MAIN
var conversation_done: bool = false
var touch_done: bool = false
var stat_changed: bool = false

@onready var status_label: Label      = $CanvasLayer/VBox/StatusLabel
@onready var result_label: Label      = $CanvasLayer/VBox/ResultLabel
@onready var main_panel: VBoxContainer   = $CanvasLayer/VBox/MainPanel
@onready var conv_panel: VBoxContainer   = $CanvasLayer/VBox/ConvPanel
@onready var touch_panel: VBoxContainer  = $CanvasLayer/VBox/TouchPanel

func _ready() -> void:
	_update_status()
	_show_phase(Phase.MAIN)

func _update_status() -> void:
	status_label.text = GameState.get_status_text()

func _show_phase(phase: Phase) -> void:
	current_phase = phase
	main_panel.visible  = (phase == Phase.MAIN)
	conv_panel.visible  = (phase == Phase.CONVERSATION)
	touch_panel.visible = (phase == Phase.TOUCH)
	result_label.text   = ""

# ---- メインアクション ----

func _on_talk_button_pressed() -> void:
	_show_phase(Phase.CONVERSATION)

func _on_touch_button_pressed() -> void:
	_rebuild_touch_buttons()
	_show_phase(Phase.TOUCH)

func _on_status_button_pressed() -> void:
	result_label.text = GameState.get_status_text()
	_show_phase(Phase.STATUS)
	main_panel.visible = true

# ---- 会話 ----

func _on_conv_success_pressed() -> void:
	GameState.apply_conversation_result("success")
	result_label.text = "上手く話せた！（好感度 +3）"
	conversation_done = true
	stat_changed = true
	_update_status()
	_check_transition()

func _on_conv_normal_pressed() -> void:
	GameState.apply_conversation_result("normal")
	result_label.text = "普通の会話だった。（好感度 +1）"
	conversation_done = true
	stat_changed = true
	_update_status()
	_check_transition()

func _on_conv_fail_pressed() -> void:
	GameState.apply_conversation_result("fail")
	result_label.text = "会話が失敗した…"
	conversation_done = true
	stat_changed = true   # 失敗でも遷移トリガー
	_update_status()
	_check_transition()

func _on_conv_back_pressed() -> void:
	_show_phase(Phase.MAIN)

# ---- ふれあい ----

func _rebuild_touch_buttons() -> void:
	# 既存ボタンを削除
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
	touch_done = true
	stat_changed = true
	_update_status()
	_check_transition()

func _on_touch_back_pressed() -> void:
	_show_phase(Phase.MAIN)

# ---- 夜シーンへ遷移チェック ----

func _check_transition() -> void:
	_show_phase(Phase.MAIN)
	if stat_changed:
		var next_btn := Button.new()
		next_btn.text = "夜へ進む"
		next_btn.pressed.connect(_go_to_night)
		main_panel.add_child(next_btn)

func _go_to_night() -> void:
	get_tree().change_scene_to_file("res://scenes/night/NightScene.tscn")
