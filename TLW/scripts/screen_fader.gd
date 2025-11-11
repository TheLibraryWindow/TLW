extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	if not rect:
		push_error("❌ ScreenFader: Could not find ColorRect")
		return
	rect.color = Color.BLACK
	rect.color.a = 0.0   # start transparent
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_in(duration: float = 0.5) -> void:
	print("[FADER] fade_in start")
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, duration)
	await tween.finished
	print("[FADER] fade_in done")

func fade_out(duration: float = 0.5) -> void:
	print("[FADER] fade_out start")
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration)
	await tween.finished
	print("[FADER] fade_out done")
