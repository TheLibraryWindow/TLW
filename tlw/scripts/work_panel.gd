extends "res://scripts/settings_panel.gd"

const STATUS_INACTIVE_COLOR := Color(0.149, 0.165, 0.18, 1.0)
const STATUS_ACTIVE_COLOR := Color(0.376, 0.709, 0.835, 1.0)
const STATUS_COMPLETE_COLOR := Color(0.701, 0.823, 0.901, 1.0)
const STATUS_TEXT_MUTED := Color(0.65, 0.72, 0.78, 0.85)
const STATUS_TEXT_ACTIVE := Color(0.88, 0.95, 1.0, 1.0)

const RAIL_INACTIVE_COLOR := Color(0.113, 0.125, 0.137, 1.0)
const RAIL_ACTIVE_COLOR := Color(0.364, 0.701, 0.819, 1.0)

const ALERT_MESSAGES := [
	"Audit bulletin: terminal latency flagged. Remain still.",
	"Notice: observation feed 7C recalibrating.",
	"Reminder: worker outputs logged per microcycle.",
	"Directive: suppress emotional variance during tasks.",
	"Alert: central oracle demanding cleaner data.",
	"Memo: persistent noise indicates rival department.",
	"Flag: judgement buffer nearing overflow.",
	"Ping: inspector drones watching this console."
]

const QUESTION_ARCHIVE := [
	"[color=#6dd1ff]Extract[/color] coordinates embedded in the witness ledger.",
	"Decode the intercepted [color=#8fffd0]syllable stack[/color] and report anomalies.",
	"Strip identifiers from cargo manifest 55-Δ and provide residual sum.",
	"Summarize surveillance vignette C9 without implicating the overseer.",
	"Project fallout radius for malfunctioning coolant rod Ψ-4.",
	"Cross-match ration ledger with ghost accounts flagged last cycle.",
	"Translate chant fragments recovered from maintenance shaft 12.",
	"Identify which worker signature deviates from algorithmic norm.",
	"Reconstruct missing frames from camera nest K//32.",
	"Surface all references to project CATHODE in message queue 91."
]

const REWARD_CODES := [
	"Ration stub 14-B",
	"Scrap axis 0091",
	"Coordinate ∑(31.09, -12.44)",
	"Chit: 0.25 kilowatt minutes",
	"Tag IRN-778",
	"One bolt (oxidized)",
	"Audit token 3C",
	"Barcode shard 9917",
	"Spent fuse #442",
	"Invalid parking docket"
]

const REWARD_ICONS := ["⛃", "⌬", "⍑", "✶", "⦿"]
const RAIL_CODES := ["A1", "A2", "B1", "B2", "C1", "C2"]
const RAIL_TEXT_ACTIVE_COLOR := Color(0.74, 0.82, 0.87, 0.95)
const RAIL_TEXT_INACTIVE_COLOR := Color(0.48, 0.51, 0.53, 0.88)
const RAIL_STATUS_ACTIVE_COLOR := Color(0.47, 0.84, 0.91, 1.0)
const RAIL_STATUS_INACTIVE_COLOR := Color(0.37, 0.41, 0.44, 0.8)
const RAIL_NODE_SIZE := Vector2(72, 54)
const RAIL_HALO_COLOR := Color(0.27451, 0.972549, 0.996078, 0.22)
const RAIL_HALO_MARGIN := 6.0
const AUDIT_DEFAULT_MESSAGE := "Audit bulletin: new worker"

@onready var designation_label: Label = %DesignationLabel
@onready var quota_label: Label = %QuotaLabel
@onready var quota_progress: ProgressBar = %QuotaProgress
@onready var audit_ticker: Label = %AuditTicker
@onready var question_feed: RichTextLabel = %QuestionFeed
@onready var question_id_label: Label = %QuestionIdLabel
@onready var glitch_overlay: Label = %GlitchOverlay
@onready var scan_lines: ColorRect = %ScanLines
@onready var question_frame: Panel = %QuestionFrame
@onready var answer_field: LineEdit = %AnswerField
@onready var submit_button: Button = %SubmitButton
@onready var status_list: VBoxContainer = %StatusList
@onready var ticket_reward_label: Label = %TicketRewardLabel
@onready var ticket_icon: Label = %TicketIcon
@onready var door_left: ColorRect = %DoorLeft
@onready var door_right: ColorRect = %DoorRight
@onready var rail_timer: Timer = %RailTimer
@onready var glitch_timer: Timer = %GlitchTimer
@onready var alert_timer: Timer = %AlertTimer
@onready var left_rail: VBoxContainer = %LeftRail

var _rail_nodes: Array[ColorRect] = []
var _rail_code_labels: Array[Label] = []
var _rail_status_labels: Array[Label] = []
var _rail_halo_nodes: Array[Node] = []
var _status_rows: Array = []
var _rng := RandomNumberGenerator.new()
var _processing := false
var _door_left_closed := Vector2.ZERO
var _door_right_closed := Vector2.ZERO


func _ready() -> void:
	super._ready()
	_rng.randomize()
	_cache_nodes()
	_connect_signals()
	_reset_status_rows()
	_update_designation()
	_pull_new_prompt()
	call_deferred("_capture_door_positions")


func _capture_door_positions() -> void:
	if is_instance_valid(door_left):
		_door_left_closed = door_left.position
	if is_instance_valid(door_right):
		_door_right_closed = door_right.position


func _cache_nodes() -> void:
	if left_rail:
		var rail_container := left_rail.get_node_or_null("RailNodes")
		if rail_container:
			for child in rail_container.get_children():
				if child is ColorRect:
					_configure_rail_node(child)
					_rail_nodes.append(child)
					_rail_code_labels.append(child.get_node("CodeLabel") as Label)
					_rail_status_labels.append(child.get_node("StatusLabel") as Label)
					_rail_halo_nodes.append(child.get_node("Halo"))
		_configure_rail_labels()
	if not _rail_nodes.is_empty():
		_prime_rail_nodes()
		if rail_timer:
			rail_timer.stop()
	if status_list:
		for row in status_list.get_children():
			var indicator := row.get_node_or_null("Indicator") as ColorRect
			var label := row.get_node_or_null("Label") as Label
			if indicator and label:
				_status_rows.append({"indicator": indicator, "label": label})


func _connect_signals() -> void:
	if submit_button and not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
	if answer_field and not answer_field.text_submitted.is_connected(_on_answer_submitted):
		answer_field.text_submitted.connect(_on_answer_submitted)
	if rail_timer and not rail_timer.timeout.is_connected(_on_rail_timer_timeout):
		rail_timer.timeout.connect(_on_rail_timer_timeout)
	if glitch_timer and not glitch_timer.timeout.is_connected(_on_glitch_timer_timeout):
		glitch_timer.timeout.connect(_on_glitch_timer_timeout)
	if alert_timer and not alert_timer.timeout.is_connected(_on_alert_timer_timeout):
		alert_timer.timeout.connect(_on_alert_timer_timeout)
		alert_timer.stop()


func _apply_neon_style() -> void:
	# Override parent neon theme with industrial finish
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.039, 0.043, 0.05, 1.0)
	panel_box.border_color = Color(0.247, 0.376, 0.47, 1.0)
	panel_box.set_border_width_all(2)
	panel_box.corner_radius_top_left = 2
	panel_box.corner_radius_top_right = 2
	panel_box.corner_radius_bottom_left = 2
	panel_box.corner_radius_bottom_right = 2
	add_theme_stylebox_override("panel", panel_box)

	if topbar:
		topbar.color = Color(0.082, 0.09, 0.101, 1.0)
	if title_label:
		title_label.text = "Labor Terminal"
		title_label.add_theme_color_override("font_color", Color(0.56, 0.78, 0.96, 1.0))
	for button in [close_btn, min_btn, max_btn]:
		if button:
			button.flat = true
			button.add_theme_color_override("font_color", Color(0.8, 0.88, 0.94, 1.0))

	var question_box := StyleBoxFlat.new()
	question_box.bg_color = Color(0.023, 0.027, 0.031, 1.0)
	question_box.border_color = Color(0.227, 0.368, 0.45, 1.0)
	question_box.set_border_width_all(1)
	if question_frame:
		question_frame.add_theme_stylebox_override("panel", question_box)


func _on_submit_pressed() -> void:
	if _processing:
		return
	var payload := answer_field.text.strip_edges() if answer_field else ""
	if payload.is_empty():
		payload = "[null transmission]"
	_processing = true
	_toggle_submission_inputs(false)
	await _play_status_sequence()
	await _dispense_reward(payload)
	_toggle_submission_inputs(true)
	_processing = false
	if answer_field:
		answer_field.clear()
	_pull_new_prompt()


func _on_answer_submitted(_text: String) -> void:
	_on_submit_pressed()


func _toggle_submission_inputs(enabled: bool) -> void:
	if submit_button:
		submit_button.disabled = not enabled
	if answer_field:
		answer_field.editable = enabled


func _play_status_sequence() -> void:
	_reset_status_rows()
	for index in _status_rows.size():
		_set_status_state(index, STATUS_ACTIVE_COLOR, STATUS_TEXT_ACTIVE)
		if index > 0:
			_set_status_state(index - 1, STATUS_COMPLETE_COLOR, STATUS_TEXT_ACTIVE)
		await get_tree().create_timer(0.5, false).timeout
	if not _status_rows.is_empty():
		_set_status_state(_status_rows.size() - 1, STATUS_COMPLETE_COLOR, STATUS_TEXT_ACTIVE)
	await get_tree().create_timer(0.25, false).timeout


func _dispense_reward(payload: String) -> void:
	_adjust_quota()
	var code: String = REWARD_CODES[_rng.randi_range(0, REWARD_CODES.size() - 1)]
	var icon: String = REWARD_ICONS[_rng.randi_range(0, REWARD_ICONS.size() - 1)]
	if ticket_reward_label:
		ticket_reward_label.text = "%s // echo of \"%s\"" % [code, payload.substr(0, min(18, payload.length()))]
	if ticket_icon:
		ticket_icon.text = icon
	await _animate_ticket_doors(true)
	await get_tree().create_timer(1.1, false).timeout
	await _animate_ticket_doors(false)


func _animate_ticket_doors(open: bool) -> void:
	if not (is_instance_valid(door_left) and is_instance_valid(door_right)):
		return
	var spread := 52.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	var target_left := _door_left_closed.x - (spread if open else 0.0)
	var target_right := _door_right_closed.x + (spread if open else 0.0)
	tween.tween_property(door_left, "position:x", target_left, 0.28)
	tween.parallel().tween_property(door_right, "position:x", target_right, 0.28)
	await tween.finished
	if not open:
		door_left.position = _door_left_closed
		door_right.position = _door_right_closed


func _reset_status_rows() -> void:
	for row in _status_rows:
		_set_row_visual(row, STATUS_INACTIVE_COLOR, STATUS_TEXT_MUTED)


func _set_status_state(index: int, color: Color, text_color: Color) -> void:
	if index < 0 or index >= _status_rows.size():
		return
	_set_row_visual(_status_rows[index], color, text_color)


func _set_row_visual(row: Dictionary, color: Color, text_color: Color) -> void:
	var indicator: ColorRect = row.get("indicator")
	var label: Label = row.get("label")
	if indicator:
		indicator.color = color
	if label:
		label.add_theme_color_override("font_color", text_color)


func _adjust_quota() -> void:
	if not quota_progress:
		return
	var delta := _rng.randi_range(4, 12)
	quota_progress.value = fposmod(quota_progress.value + delta, quota_progress.max_value)
	if quota_label:
		quota_label.text = "Labor quota: %02d%%" % int(quota_progress.value)


func _pull_new_prompt() -> void:
	if QUESTION_ARCHIVE.is_empty():
		return
	var text: String = QUESTION_ARCHIVE[_rng.randi_range(0, QUESTION_ARCHIVE.size() - 1)]
	if question_feed:
		question_feed.text = text
	if question_id_label:
		question_id_label.text = "FILE REF :: %s" % _random_file_code()


func _random_file_code() -> String:
	var shard_letters := [
		char(int('A') + _rng.randi_range(0, 25)),
		char(int('A') + _rng.randi_range(0, 25))
	]
	var shard := "".join(shard_letters)
	return "%d-%s%s" % [_rng.randi_range(10, 99), shard, str(_rng.randi_range(0, 9))]


func _update_designation() -> void:
	var worker_id := "%dX-%03d" % [_rng.randi_range(1, 9), _rng.randi_range(0, 999)]
	if designation_label:
		designation_label.text = "Worker: %s" % worker_id
	if quota_progress:
		quota_progress.max_value = 120.0
		quota_progress.value = 0.0
	if quota_label:
		quota_label.text = "Labor quota: %02d%%" % int(quota_progress.value)


func _on_rail_timer_timeout() -> void:
	_prime_rail_nodes()


func _prime_rail_nodes() -> void:
	for index in _rail_nodes.size():
		var node := _rail_nodes[index]
		if node:
			node.color = RAIL_ACTIVE_COLOR if index == 0 else RAIL_INACTIVE_COLOR
		if index < _rail_code_labels.size():
			var code_label := _rail_code_labels[index]
			if code_label:
				code_label.add_theme_color_override("font_color", RAIL_TEXT_ACTIVE_COLOR if index == 0 else RAIL_TEXT_INACTIVE_COLOR)
		if index < _rail_status_labels.size():
			var status_label := _rail_status_labels[index]
			if status_label:
				if index == 0:
					status_label.text = "Activated"
					status_label.add_theme_color_override("font_color", RAIL_STATUS_ACTIVE_COLOR)
				else:
					status_label.text = ""
					status_label.add_theme_color_override("font_color", RAIL_STATUS_INACTIVE_COLOR)
		if index < _rail_halo_nodes.size():
			var halo := _rail_halo_nodes[index]
			if halo:
				halo.visible = (index == 0)


func _on_glitch_timer_timeout() -> void:
	if not question_feed:
		return
	var jitter := _rng.randf_range(-0.04, 0.04)
	question_frame.scale = Vector2(1.0 + jitter, 1.0 + jitter)
	scan_lines.color = Color(1, 1, 1, _rng.randf_range(0.02, 0.12))
	glitch_overlay.text = "// audit trace %03d.%d" % [_rng.randi_range(100, 999), _rng.randi_range(0, 9)]
	glitch_overlay.modulate = Color(0.6, 0.8, 1.0, _rng.randf_range(0.25, 0.6))


func _on_alert_timer_timeout() -> void:
	if audit_ticker:
		audit_ticker.text = AUDIT_DEFAULT_MESSAGE


func _configure_rail_labels() -> void:
	for index in _rail_nodes.size():
		if index < _rail_code_labels.size():
			var code_label := _rail_code_labels[index]
			if code_label:
				var code_text: String = RAIL_CODES[index] if index < RAIL_CODES.size() else str(index)
				code_label.text = code_text
				code_label.add_theme_color_override("font_color", RAIL_TEXT_INACTIVE_COLOR)
		if index < _rail_status_labels.size():
			var status_label := _rail_status_labels[index]
			if status_label:
				status_label.text = ""
				status_label.add_theme_color_override("font_color", RAIL_STATUS_INACTIVE_COLOR)
	if audit_ticker:
		audit_ticker.text = AUDIT_DEFAULT_MESSAGE


func _configure_rail_node(node: ColorRect) -> void:
	node.custom_minimum_size = RAIL_NODE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node.get_node_or_null("Halo") == null:
		var halo := ColorRect.new()
		halo.name = "Halo"
		halo.color = RAIL_HALO_COLOR
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halo.z_index = -1
		halo.anchor_left = 0.0
		halo.anchor_top = 0.0
		halo.anchor_right = 1.0
		halo.anchor_bottom = 1.0
		halo.offset_left = -RAIL_HALO_MARGIN
		halo.offset_top = -RAIL_HALO_MARGIN
		halo.offset_right = RAIL_HALO_MARGIN
		halo.offset_bottom = RAIL_HALO_MARGIN
		node.add_child(halo)
	if node.get_node_or_null("CodeLabel") == null:
		var code_label := Label.new()
		code_label.name = "CodeLabel"
		code_label.anchor_left = 0.0
		code_label.anchor_top = 0.0
		code_label.anchor_right = 1.0
		code_label.anchor_bottom = 1.0
		code_label.offset_left = 4.0
		code_label.offset_right = -4.0
		code_label.offset_top = 4.0
		code_label.offset_bottom = -22.0
		code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(code_label)
	if node.get_node_or_null("StatusLabel") == null:
		var status_label := Label.new()
		status_label.name = "StatusLabel"
		status_label.anchor_left = 0.0
		status_label.anchor_top = 0.0
		status_label.anchor_right = 1.0
		status_label.anchor_bottom = 1.0
		status_label.offset_left = 4.0
		status_label.offset_right = -4.0
		status_label.offset_top = 24.0
		status_label.offset_bottom = -4.0
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(status_label)
