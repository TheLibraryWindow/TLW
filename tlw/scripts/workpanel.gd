extends "res://scripts/settings_panel.gd"

@export var question_label_path: NodePath = NodePath("BodyContainer/QuestionLabel")

var _question_label: Label


func _ready() -> void:
	super._ready()
	_question_label = get_node_or_null(question_label_path) as Label


func toggle_visibility(animated: bool = true) -> void:
	if visible:
		hide_panel(animated)
	else:
		show_panel(animated)


func show_panel(animated: bool = true) -> void:
	super.show_panel(animated)


func hide_panel(animated: bool = true, reason: String = "", on_done: Callable = Callable()) -> void:
	super.hide_panel(animated, reason, on_done)


func show_question(text: String) -> void:
	if _question_label:
		_question_label.text = text
	show_panel()
