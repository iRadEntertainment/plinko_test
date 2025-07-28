extends Control
class_name HUD

var game: Game
var board: Board:
	get: return game.board


func _ready() -> void:
	game = get_parent()
	if not game.is_node_ready(): await game.ready
	update_hud_values()
	board.balls_count_updated.connect(_on_balls_count_updated)


func update_hud_values() -> void:
	%sl_bump_count.value = board.bumper_col_count #3,50
	%sl_goal_count.value = board.goal_area_spots #2,30
	%sl_spawn_area_width.value = board.spawn_width_ratio #0,1
	%lb_bump_count.text = "%d" % %sl_bump_count.value
	%lb_goal_count.text = "%d" % %sl_goal_count.value
	%lb_spawn_area_width.text = "%0.2f" % %sl_spawn_area_width.value


func _on_balls_count_updated(count: int) -> void:
	%lb_ball_count.text = str(count)


func _on_btn_start_pressed() -> void:
	board.spawn_balls()


func _on_btn_clear_pressed() -> void:
	board.clear_balls()


func _on_btn_swap_pressed() -> void:
	board.swap_gravity()

func _on_sl_bump_count_value_changed(value: float) -> void:
	%lb_bump_count.text = "%d" % value
func _on_sl_goal_count_value_changed(value: float) -> void:
	%lb_goal_count.text = "%d" % value
func _on_sl_spawn_area_width_value_changed(value: float) -> void:
	%lb_spawn_area_width.text = "%0.2f" % value
func _on_sl_bump_count_drag_ended(value_changed: bool) -> void:
	if not value_changed: return
	board.bumper_col_count = int(%sl_bump_count.value)
func _on_sl_goal_count_drag_ended(value_changed: bool) -> void:
	if not value_changed: return
	board.goal_area_spots = int(%sl_goal_count.value)
func _on_sl_spawn_area_width_drag_ended(value_changed: bool) -> void:
	if not value_changed: return
	board.spawn_width_ratio = float(%sl_spawn_area_width.value)
func _on_sl_spawn_area_width_mouse_entered() -> void:
	board.show_spawn_rect = true
func _on_sl_spawn_area_width_mouse_exited() -> void:
	board.show_spawn_rect = false


func _on_btn_settings_pressed() -> void:
	%pnl_tools.visible = !%pnl_tools.visible
