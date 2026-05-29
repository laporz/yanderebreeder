extends Node

## MorningScene: 会話・ふれあい・ステータス確認

enum Phase { MAIN, TOUCH, STATUS }

var current_phase: Phase = Phase.MAIN
var stat_changed: bool = false
var _next_button: Button = null

@onready var status_label: Label          = $CanvasLayer/VBox/StatusLabel
@onready var main_panel: VBoxContainer    = $CanvasLayer/VBox/MainPanel
@onready var touch_panel: VBoxContainer   = $CanvasLayer/VBox/TouchPanel
@onready var result_label: Label          = $CanvasLayer/VBox/ResultLabel
@onready var character_view               = $CharacterView
@onready var dialogue_box                 = $DialogueBox
@onready var save_panel                   = $SavePanel

func _ready() -> void:
	_update_status()
	_show_phase(Phase.MAIN)
	dialogue_box.choice_selected.connect(_on_choice_selected)
	dialogue_box.reply_finished.connect(_on_reply_finished)
	save_panel.slot_action_done.connect(_on_save_done)
	# 立ち絵初期表示
	var tier := DialogueDB.get_tier_data("morning")
	if not tier.is_empty():
		character_view.show_default(tier.get("outfit", "normal"))

func _update_status() -> void:
	status_label.text = GameState.get_status_text()

func _show_phase(phase: Phase) -> void:
	current_phase = phase
	main_panel.visible  = (phase == Phase.MAIN)
	touch_panel.visible = (phase == Phase.TOUCH)

# ---- メインアクション ----

func _on_talk_button_pressed() -> void:
	var tier := DialogueDB.get_tier_data("morning")
	if tier.is_empty():
		result_label.text = "（会話データがありません）"
		return
	dialogue_box.show_choices(tier.get("prompt", ""), tier.get("choices", []))

func _on_touch_button_pressed() -> void:
	_rebuild_touch_buttons()
	_show_phase(Phase.TOUCH)

func _on_status_button_pressed() -> void:
	result_label.text = GameState.get_status_text()

func _on_save_button_pressed() -> void:
	save_panel.open_save_mode("morning")

# ---- セーブ完了 ----

func _on_save_done(_slot: String) -> void:
	result_label.text = "セーブしました。"

# ---- 会話（DialogueBox経由）----

func _on_choice_selected(choice: Dictionary) -> void:
	GameState.apply_conversation_result(choice.get("outcome", "fail"))
	var tier := DialogueDB.get_tier_data("morning")
	character_view.show_expression(
		tier.get("outfit", "normal"),
		choice.get("expression", "default")
	)
	dialogue_box.show_reply(choice.get("reply", "……。"))
	stat_changed = true

func _on_reply_finished() -> void:
	_update_status()
	dialogue_box.hide_box()
	_check_transition()

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
	stat_changed = true
	_update_status()
	_check_transition()

func _on_touch_back_pressed() -> void:
	_show_phase(Phase.MAIN)

# ---- 夜へ遷移チェック ----

func _check_transition() -> void:
	_show_phase(Phase.MAIN)
	if stat_changed and _next_button == null:
		_next_button = Button.new()
		_next_button.text = "🌙 夜へ進む"
		_next_button.pressed.connect(_go_to_night)
		main_panel.add_child(_next_button)

func _go_to_night() -> void:
	get_tree().change_scene_to_file("res://scenes/night/NightScene.tscn")
