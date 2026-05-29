extends Node

## NightScene: 買い物・食事・ふれあい・就寝

enum Phase { MAIN, TOUCH }
var current_phase: Phase = Phase.MAIN

@onready var status_label: Label         = $CanvasLayer/VBox/StatusLabel
@onready var result_label: Label         = $CanvasLayer/VBox/ResultLabel
@onready var main_panel: VBoxContainer   = $CanvasLayer/VBox/MainPanel
@onready var touch_panel: VBoxContainer  = $CanvasLayer/VBox/TouchPanel
@onready var character_view              = $CharacterView
@onready var dialogue_box                = $DialogueBox
@onready var save_panel                  = $SavePanel

func _ready() -> void:
	_update_status()
	_show_phase(Phase.MAIN)
	dialogue_box.choice_selected.connect(_on_choice_selected)
	dialogue_box.reply_finished.connect(_on_reply_finished)
	save_panel.slot_action_done.connect(_on_save_done)
	# 立ち絵初期表示（夜はパジャマ）
	var tier := DialogueDB.get_tier_data("night")
	if not tier.is_empty():
		character_view.show_default(tier.get("outfit", "pajama"))

func _update_status() -> void:
	status_label.text = GameState.get_status_text()

func _show_phase(phase: Phase) -> void:
	current_phase = phase
	main_panel.visible  = (phase == Phase.MAIN)
	touch_panel.visible = (phase == Phase.TOUCH)

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
	var tier := DialogueDB.get_tier_data("night")
	if tier.is_empty():
		result_label.text = "（会話データがありません）"
		return
	dialogue_box.show_choices(tier.get("prompt", ""), tier.get("choices", []))

func _on_touch_pressed() -> void:
	_rebuild_touch_buttons()
	_show_phase(Phase.TOUCH)

func _on_save_button_pressed() -> void:
	save_panel.open_save_mode("night")

func _on_save_done(_slot: String) -> void:
	result_label.text = "セーブしました。"

func _on_sleep_pressed() -> void:
	if GameState.pleasure > 50:
		get_tree().change_scene_to_file("res://scenes/midnight/MidnightScene.tscn")
	else:
		_next_day()

# ---- 会話（DialogueBox経由）----

func _on_choice_selected(choice: Dictionary) -> void:
	GameState.apply_conversation_result(choice.get("outcome", "fail"))
	var tier := DialogueDB.get_tier_data("night")
	character_view.show_expression(
		tier.get("outfit", "pajama"),
		choice.get("expression", "default")
	)
	dialogue_box.show_reply(choice.get("reply", "……。"))

func _on_reply_finished() -> void:
	_update_status()
	dialogue_box.hide_box()
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
	SaveManager.auto_save("morning")   # 翌日開始前にオートセーブ
	get_tree().change_scene_to_file("res://scenes/morning/MorningScene.tscn")
