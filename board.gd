@tool
extends Node2D
class_name Board

@export_tool_button("DO IT") var _do_it = update_board

@export var physics_material_balls: PhysicsMaterial
@export var physics_material_bumpers: PhysicsMaterial
@export var physics_material_walls: PhysicsMaterial

@export_group("Board")
@export var tot_dimensions: Vector2 = Vector2(800, 1024):
	set(val):
		tot_dimensions = val
		update_board()
@export_range(2, 30) var goal_area_spots: int = 8:
	set(val):
		goal_area_spots = val
		update_board()

@export_subgroup("Finesse")
@export_range(1.0, 128.0, 0.5) var wall_thickness: float = 24.0:
	set(val):
		wall_thickness = val
		update_board()
@export_range(0.01, 1.0, 0.01) var goal_area_height_ratio: float = 0.5:
	set(val):
		goal_area_height_ratio = val
		update_board()
@export_range(0.0, 1.0, 0.01) var post_width_ratio: float = 0.2:
	set(val):
		post_width_ratio = val
		update_board()

@export_subgroup("Bumpers")
@export_range(3, 50) var bumper_col_count: int = 10:
	set(val):
		bumper_col_count = val
		update_board()
@export_range (0.01, 1.0, 0.01) var bumper_dimension_ratio: float = 0.5:
	set(val):
		bumper_dimension_ratio = val
		update_board()


@export_subgroup("Gaps")
@export_range(0.0, 512.0, 0.5) var spawn_to_bumpers_gap: float = 48.0:
	set(val):
		spawn_to_bumpers_gap = val
		update_board()
@export_range(0.0, 512.0, 0.5) var bumpers_to_goal_gap: float = 48.0:
	set(val):
		bumpers_to_goal_gap = val
		update_board()
@export_range(0.0, 1.0, 0.01) var spawn_width_ratio: float =  .33:
	set(val):
		spawn_width_ratio = val
		update_board()

@export_subgroup("Debug")
@export var _visible_colliders: bool = false:
	set(val):
		_visible_colliders = val
		update_colliders_visibility()

# globals
var dimensions: Vector2
var goal_area_height: float
var post_width: float
var bumper_radius: float
var bumper_first_row_center_y: float
var bumper_col_spacing: float
var bumper_row_spacing: float
var bumper_last_row_center_y: float
var spawn_rect: Rect2
var show_spawn_rect: bool = false:
	set(val): show_spawn_rect = val; queue_redraw()
var balls: Array[RigidBody2D]
var balls_count: int:
	get: return balls.size()
var gravity: Vector2:
	get: return PhysicsServer2D.area_get_param(get_viewport().find_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR)

signal balls_count_updated(balls_count: int)


func _ready() -> void:
	if not Engine.is_editor_hint():
		#update_board()
		pass


var is_spawning: bool = false
var tw_spawn: Tween
const SPAWN_TIME: float = 1.5
const BALL_RES: int = 16
func spawn_balls(amount: int = 300) -> void:
	if Engine.is_editor_hint():
		return
	if is_spawning:
		return
	is_spawning = true
	var ball_shape := CircleShape2D.new()
	ball_shape.radius = bumper_radius
	var circle_points := PackedVector2Array()
	for i in BALL_RES:
		var angle: float = float(i) * TAU / BALL_RES
		circle_points.append(Vector2.from_angle(angle) * bumper_radius)
	var new_balls: Array[RigidBody2D] = []
	for i in amount:
		var new_ball := RigidBody2D.new()
		new_ball.physics_material_override = physics_material_balls
		#new_ball.can_sleep = false
		new_ball.position.x = randf_range(spawn_rect.position.x, spawn_rect.end.x)
		new_ball.position.y = randf_range(spawn_rect.position.y, spawn_rect.end.y)
		new_ball.tree_entered.connect(func(): balls.append(new_ball); balls_count_updated.emit(balls_count))
		new_ball.tree_exited.connect(func(): balls.erase(new_ball); balls_count_updated.emit(balls_count))
		
		var coll := CollisionShape2D.new()
		coll.shape = ball_shape
		
		var ball_poly := Polygon2D.new()
		ball_poly.polygon = circle_points
		ball_poly.color = Color.DEEP_PINK
		
		new_ball.add_child(coll)
		new_ball.add_child(ball_poly)
		new_balls.append(new_ball)
	
	if tw_spawn:
		tw_spawn.kill()
	tw_spawn = create_tween()
	tw_spawn.set_parallel()
	var step: float = SPAWN_TIME/new_balls.size()
	for i: int in new_balls.size():
		var new_ball: RigidBody2D = new_balls[i]
		tw_spawn.tween_callback(%balls.add_child.bind(new_ball)).set_delay(step*i)
	
	tw_spawn.chain().tween_property(self, ^"is_spawning", false, 0.0)
	#await tw_spawn.finished
	#is_spawning = false


var tw_clear: Tween
const CLEAR_TIME: float = 1.5
func clear_balls() -> void:
	if tw_clear:
		tw_clear.kill()
	tw_clear = create_tween()
	tw_clear.set_parallel(true)
	
	var tot_balls: int = %balls.get_child_count()
	var step: float = CLEAR_TIME / tot_balls
	for i: int in tot_balls:
		var ball: RigidBody2D = %balls.get_child(i)
		if not ball.is_queued_for_deletion():
			tw_clear.tween_callback(ball.queue_free).set_delay(step * i)


var tw_swap: Tween
var is_gravity_down: bool = true
func swap_gravity() -> void:
	if tw_swap:
		tw_swap.kill()
	is_gravity_down = gravity.y > 0
	var to_gravity: Vector2 = Vector2.UP if is_gravity_down else Vector2.DOWN
	tw_swap = create_tween()
	tw_swap.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_swap.tween_method(set_gravity, gravity, to_gravity, 0.6)


func set_gravity(dir: Vector2) -> void:
	PhysicsServer2D.area_set_param(get_viewport().find_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, dir)
	call_deferred(&"wake_up_balls")


func wake_up_balls() -> void:
	for ball: RigidBody2D in balls:
		ball.set_deferred("sleeping", false)


func update_board() -> void:
	if not is_node_ready():
		await ready
	# update globals
	dimensions = tot_dimensions - Vector2(wall_thickness * 2, wall_thickness)
	goal_area_height = dimensions.y * goal_area_height_ratio / 2.0
	if post_width_ratio == 0.0:
		post_width = min(wall_thickness, dimensions.x / (goal_area_spots-1))
	else:
		post_width = dimensions.x * post_width_ratio / (goal_area_spots-1)
	
	bumper_col_spacing = dimensions.x / (bumper_col_count)
	bumper_row_spacing = sqrt(3) * bumper_col_spacing * 0.5
	bumper_radius = bumper_col_spacing * bumper_dimension_ratio * 0.5
	bumper_first_row_center_y = spawn_to_bumpers_gap + bumper_radius/2.0
	bumper_last_row_center_y = dimensions.y - bumpers_to_goal_gap - goal_area_height - bumper_radius/2.0
	
	spawn_rect = Rect2()
	spawn_rect.size.x = dimensions.x * spawn_width_ratio
	spawn_rect.size.y = spawn_to_bumpers_gap - bumper_row_spacing
	spawn_rect.position.x = (dimensions.x - spawn_rect.size.x) / 2.0 + wall_thickness
	spawn_rect.position.y = 0
	
	#print("bumper_col_spacing: ", bumper_col_spacing)
	#print("bumper_row_spacing: ", bumper_row_spacing)
	#print("bumper_radius: ", bumper_radius)
	#print("bumper_first_row_center_y: ", bumper_first_row_center_y)
	#print("bumper_last_row_center_y: ", bumper_last_row_center_y)
	
	
	# borders
	%board_collisions.physics_material_override = physics_material_walls
	%w_coll_left.position = Vector2(wall_thickness, tot_dimensions.y/2)
	%w_coll_right.position = Vector2(dimensions.x + wall_thickness, tot_dimensions.y/2)
	%w_coll_bot.position = Vector2(tot_dimensions.x/2, dimensions.y)
	%boundary_poly.polygon = [
		Vector2(), Vector2(0,tot_dimensions.y), tot_dimensions, Vector2(tot_dimensions.x, 0),
		Vector2(tot_dimensions.x - wall_thickness, 0), Vector2(tot_dimensions.x - wall_thickness, dimensions.y),
		Vector2(wall_thickness, dimensions.y), Vector2(wall_thickness, 0),
	]
	
	# clear goal area
	for child: Node2D in %areas.get_children() + %posts.get_children() + %bumpers.get_children():
		child.free()
	
	# populate goal area
	var posts_and_area_center_y: float = dimensions.y - (goal_area_height / 2.0)
	
	var area_rect_shape := RectangleShape2D.new()
	area_rect_shape.size.x = (dimensions.x - post_width * (goal_area_spots - 1)) / goal_area_spots
	area_rect_shape.size.y = goal_area_height
	var post_rect_shape := RectangleShape2D.new()
	post_rect_shape.size.x = post_width
	post_rect_shape.size.y = goal_area_height + wall_thickness
	for i: int in goal_area_spots:
		# Area2D nodes
		var new_area := Area2D.new()
		new_area.name = "goal_area_%d" % (i+1)
		new_area.position.x = (area_rect_shape.size.x/2.0)
		new_area.position.x += i * (area_rect_shape.size.x + post_width)
		new_area.position.x += wall_thickness
		new_area.position.y = posts_and_area_center_y
		var new_area_coll := CollisionShape2D.new()
		new_area_coll.name = "coll_area_%d" % (i+1)
		new_area_coll.shape = area_rect_shape
		new_area.add_child(new_area_coll)
		%areas.add_child(new_area)
		if Engine.is_editor_hint():
			new_area.owner = self
			new_area_coll.owner = self
		
		# Posts
		if i < goal_area_spots-1:
			var post_center: Vector2 = Vector2()
			post_center.x = ((dimensions.x + post_width) / goal_area_spots) * (i+1)
			post_center.x += wall_thickness - post_width/2.0
			post_center.y = posts_and_area_center_y
			var new_poly := Polygon2D.new()
			new_poly.name = "post_poly_%d" % (i+1)
			new_poly.position = post_center
			new_poly.polygon = [
				Vector2(-post_width/2.0, -goal_area_height/2.0),
				Vector2(-post_width/2.0,  goal_area_height/2.0),
				Vector2( post_width/2.0,  goal_area_height/2.0),
				Vector2( post_width/2.0, -goal_area_height/2.0),
			]
			var static_post := StaticBody2D.new()
			static_post.name = "static"
			static_post.physics_material_override = physics_material_walls
			var coll := CollisionShape2D.new()
			coll.name = "coll"
			coll.shape = post_rect_shape
			coll.position.y = wall_thickness/2.0
			static_post.add_child(coll)
			new_poly.add_child(static_post)
			%posts.add_child(new_poly)
			
			if Engine.is_editor_hint():
				new_poly.owner = self
				static_post.owner = self
				coll.owner = self
	
	# bumpers
	var circle_points := PackedVector2Array()
	const CIRCLE_RES = 16
	for i in CIRCLE_RES:
		var angle: float = float(i) * TAU / CIRCLE_RES
		circle_points.append(Vector2.from_angle(angle) * bumper_radius)
	
	var bumper_shape := CircleShape2D.new()
	bumper_shape.radius = bumper_radius
	
	var y: int = 0
	while y < 350:
		var bumper_center_y: float = bumper_first_row_center_y + bumper_row_spacing * y
		if bumper_center_y > bumper_last_row_center_y:
			break
		var is_odd: bool = y % 2 != 0
		for x in bumper_col_count:
			var bumper_pos: Vector2 = Vector2(bumper_col_spacing * x ,bumper_center_y)
			bumper_pos.x += wall_thickness + bumper_col_spacing/2.0
			if is_odd:
				if x == bumper_col_count - 1:
					break
				bumper_pos.x += bumper_col_spacing/2.0
			
			var bumper_poly := Polygon2D.new()
			bumper_poly.name = "bump_poly_%d_%d" % [x, y]
			bumper_poly.position = bumper_pos
			bumper_poly.polygon = circle_points
			
			var bumper_static := StaticBody2D.new()
			bumper_static.name = "static"
			bumper_static.physics_material_override = physics_material_bumpers
			var bumper_coll := CollisionShape2D.new()
			bumper_coll.name = "coll"
			bumper_coll.shape = bumper_shape
			
			bumper_static.add_child(bumper_coll)
			bumper_poly.add_child(bumper_static)
			%bumpers.add_child(bumper_poly)
			
			if Engine.is_editor_hint():
				bumper_poly.owner = self
				bumper_static.owner = self
				bumper_coll.owner = self
		
		y += 1
	
	update_colliders_visibility()
	queue_redraw()


func update_colliders_visibility() -> void:
	for coll: CollisionShape2D in %board_collisions.get_children():
		coll.visible = _visible_colliders
	for area: Area2D in %areas.get_children():
		area.get_child(0).visible = _visible_colliders
	for poly: Polygon2D in %posts.get_children() + %bumpers.get_children():
		poly.get_child(0).visible = _visible_colliders


func _draw() -> void:
	if show_spawn_rect:
		draw_rect(spawn_rect, Color.AQUAMARINE, false, 1.5, true)
