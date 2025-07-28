@tool
extends Polygon2D
class_name PolyOutline


@export_range(0.0, 256.0, 0.5) var outline_width: float = 15.0:
	set(val):
		outline_width = val
		_update()
@export var outline_color: Color = Color.BLACK:
	set(val):
		outline_color = val
		_update()
@export var joint_mode: Line2D.LineJointMode = Line2D.LINE_JOINT_SHARP:
	set(val):
		joint_mode = val
		_update()
@export var outline_antialias: bool = true:
	set(val):
		outline_antialias = val
		_update()
@export var outline_behind: bool = true:
	set(val):
		outline_behind = val
		_update()
@export_range(0.0, 100.0, 0.1) var outline_sharp_limit: float = 50.0:
	set(val):
		outline_sharp_limit = val
		_update()

var _outline: Line2D


func _ready() -> void:
	draw.connect(_update)
	if not _outline:
		_outline = Line2D.new()
		add_child(_outline)


func _update() -> void:
	if not is_node_ready(): await ready
	_outline.sharp_limit = outline_sharp_limit
	_outline.show_behind_parent = outline_behind
	_outline.antialiased = outline_antialias
	_outline.closed = true
	_outline.joint_mode = joint_mode
	#_outline.end_cap_mode = Line2D.LINE_CAP_BOX
	#_outline.begin_cap_mode = Line2D.LINE_CAP_BOX
	_outline.default_color = outline_color
	_outline.width = outline_width
	_outline.points = polygon
