@tool
extends Panel
class_name Bubble

@export var dir: Vector2:
	set(val):
		dir = val.limit_length()
		queue_redraw()
@export_range(0.0, 1.0, 0.001) var margin_ratio: float = 0.05:
	set(val):
		margin_ratio = val
		queue_redraw()
@export_range(0.5, 10.0, 0.1) var reticle_width: float = 1.5:
	set(val):
		reticle_width = val
		queue_redraw()
@export var reticle_color: Color = Color.WHITE:
	set(val):
		reticle_color = val
		queue_redraw()
@export var bubble_color: Color = Color.LIGHT_GREEN:
	set(val):
		bubble_color = val
		queue_redraw()
@export var glass_color: Color = Color.DARK_GREEN - Color(0,0,0,0.8):
	set(val):
		glass_color = val
		queue_redraw()


var _center: Vector2
var _bubble_center: Vector2
var _bubble_radius: float
var _main_radius: float
var _inner_radius: float


func _draw() -> void:
	if not size.x or not size.y: return
	_center = size/2.0
	_main_radius = min(size.x, size.y)/2.0 * (1.0 - margin_ratio)
	_inner_radius = _main_radius * 0.25
	_bubble_radius = _inner_radius * 0.8
	_bubble_center = dir * (_main_radius - _inner_radius)
	_bubble_center += _center
	
	# bubble
	draw_circle(_bubble_center, _bubble_radius, bubble_color, true, -1.0, true)
	# reticle
	draw_circle(_center, _main_radius, glass_color, true, -1.0, true)
	draw_circle(_center, _main_radius, reticle_color, false, reticle_width, true)
	draw_circle(_center, _inner_radius, reticle_color, false, reticle_width, true)
	for _dir in [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]:
		var start: Vector2 = _dir * _inner_radius + _center
		var end: Vector2 = _dir * _inner_radius * 1.5 + _center
		draw_line(start, end, reticle_color, reticle_width, true)
