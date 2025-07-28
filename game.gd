extends Control
class_name Game


@onready var hud: HUD = %HUD
@onready var board: Board = %board

var gravity: Vector2:
	get: return board.gravity
	set(val): board.set_gravity(val)
var drag_start_pos: Vector2
var tw_gravity: Tween


func _ready() -> void:
	%bubble.hide()
	%bubble.modulate.a = 0.0
	%bubble.dir = gravity
	%cnt_announce.hide()


func _on_sub_cnt_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		drag_start_pos = event.position
		if event.is_pressed():
			show_bubble(true)
		if event.double_tap:
			if gravity == Vector2.DOWN: tween_gravity_value(Vector2.UP)
			elif gravity == Vector2.UP: tween_gravity_value(Vector2.DOWN)
			elif gravity == Vector2.ZERO: tween_gravity_value(Vector2.DOWN)
			elif gravity.y >  0.5: tween_gravity_value(Vector2.DOWN)
			elif gravity.y >  0.0: tween_gravity_value(Vector2.ZERO)
			elif gravity.y < -0.5: tween_gravity_value(Vector2.UP)
			elif gravity.y <  0.0: tween_gravity_value(Vector2.ZERO)
			show_bubble(true)
	if event is InputEventScreenDrag:
		var new_gravity: Vector2 = event.position - drag_start_pos
		new_gravity /= get_viewport().size.x/2.0
		new_gravity.x /= 2.0
		new_gravity = new_gravity.limit_length()
		if abs(new_gravity.x) < 0.1:
			new_gravity.x = 0.0
		new_gravity = (gravity + new_gravity).limit_length()
		tween_gravity_value(new_gravity)


func tween_gravity_value(new_gravity: Vector2) -> void:
	if tw_gravity:
		tw_gravity.kill()
	tw_gravity = create_tween()
	tw_gravity.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw_gravity.tween_method(board.set_gravity, board.gravity, new_gravity, 0.5)
	tw_gravity.parallel().tween_property(%bubble, ^"dir", new_gravity, 0.5)


var tw_bubble: Tween
func show_bubble(toggled: bool) -> void:
	if tw_bubble:
		tw_bubble.kill()
	tw_bubble = create_tween()
	tw_bubble.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	%bubble.visible = true
	if toggled:
		tw_bubble.tween_property(%bubble, ^"modulate:a", 1.0, 0.15).set_delay(0.08)
		tw_bubble.tween_interval(1.5)
		tw_bubble.tween_callback(show_bubble.bind(false))
	else:
		tw_bubble.tween_property(%bubble, ^"modulate:a", 0.0, 0.45).set_delay(0.8)
		tw_bubble.chain().tween_property(%bubble, ^"visible", false, 0.0)


func _on_sub_cnt_resized() -> void:
	if not is_node_ready(): await ready
	board.tot_dimensions = %sub_cnt.size
