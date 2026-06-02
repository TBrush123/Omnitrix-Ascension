extends Node2D

var generator: DungeonGenerator

func _ready():
    generator = DungeonGenerator.new()
    generator.generate()
    queue_redraw()
    var cam = Camera2D.new()
    add_child(cam)
    cam.make_current()
    cam.zoom = Vector2(0.5, 0.5)

func _draw():
    for corridor in generator.corridors:
        _draw_corridor(corridor)
    for room in generator.rooms:
        _draw_room(room)

func _draw_room(room: RoomNode) -> void:
    var rect = Rect2(room.position - room.size / 2, room.size)
    var color = Color.ORANGE_RED if room.is_furthest else  \
        Color.GOLD if room.id == 0 else Color.STEEL_BLUE
    draw_rect(rect, color)
    draw_rect(rect, Color.BLACK, false, 2.0)

func _draw_corridor(corridor: CorridorData) -> void:
    var pts = corridor.points
    var w = corridor.width
    for i in pts.size() - 1:
        var from = pts[i]
        var to = pts[i + 1]
        var rect = Rect2(
            Vector2(min(from.x, to.x) - w / 2, min(from.y, to.y) - w / 2),
            Vector2(abs(to.x - from.x) + w,    abs(to.y - from.y) + w)
        )
        draw_rect(rect, Color.DIM_GRAY)