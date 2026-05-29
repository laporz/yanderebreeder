extends CanvasLayer

## DialogueBox — ADVスタイルのメッセージボックス
## 選択肢表示・タイプライター演出・ヒロイン返答を担当

signal choice_selected(choice: Dictionary)
signal reply_finished()

const TYPEWRITER_SPEED: float = 0.04   # 秒/文字
const HEROINE_NAME: String = "エルフィア"

@onready var panel: Panel                   = $Panel
@onready var name_label: Label              = $Panel/VBox/NameLabel
@onready var message_label: RichTextLabel   = $Panel/VBox/MessageLabel
@onready var choice_container: VBoxContainer = $ChoiceContainer

var _typewriter_active: bool = false
var _full_text: String = ""
var _elapsed: float = 0.0
var _char_index: int = 0

# --- 外部インターフェース ---

## 選択肢フェーズを表示
func show_choices(prompt: String, choices: Array) -> void:
	_clear_choices()
	panel.visible = true
	name_label.text = ""
	message_label.text = prompt
	choice_container.visible = true

	for choice in choices:
		var btn := Button.new()
		btn.text = choice.get("label", "???")
		btn.pressed.connect(_on_choice_pressed.bind(choice))
		choice_container.add_child(btn)

## ヒロイン返答をタイプライターで表示
func show_reply(text: String) -> void:
	_clear_choices()
	choice_container.visible = false
	panel.visible = true
	name_label.text = HEROINE_NAME
	message_label.text = ""
	_full_text = text
	_char_index = 0
	_elapsed = 0.0
	_typewriter_active = true

## ダイアログボックスを非表示
func hide_box() -> void:
	panel.visible = false
	choice_container.visible = false
	_typewriter_active = false

# --- 内部処理 ---

func _ready() -> void:
	hide_box()

func _process(delta: float) -> void:
	if not _typewriter_active:
		return
	_elapsed += delta
	while _elapsed >= TYPEWRITER_SPEED and _char_index < _full_text.length():
		_elapsed -= TYPEWRITER_SPEED
		_char_index += 1
		message_label.text = _full_text.substr(0, _char_index)

	if _char_index >= _full_text.length():
		_typewriter_active = false
		reply_finished.emit()

func _input(event: InputEvent) -> void:
	if not _typewriter_active:
		return
	# クリックまたはスペースでスキップ
	var skip := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		skip = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		skip = true

	if skip:
		message_label.text = _full_text
		_char_index = _full_text.length()
		_typewriter_active = false
		reply_finished.emit()
		get_viewport().set_input_as_handled()

func _on_choice_pressed(choice: Dictionary) -> void:
	choice_selected.emit(choice)

func _clear_choices() -> void:
	for child in choice_container.get_children():
		child.queue_free()
