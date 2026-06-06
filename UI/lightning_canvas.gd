# lightning_canvas.gd
class_name LightningCanvas
extends Node2D

# ─────────────────────────────────────────
#  Config
# ─────────────────────────────────────────
const BOLT_COUNT:    int   = 3
const SEGMENTS:      int   = 12
const JITTER:        float = 20.0
const LINE_WIDTH:    float = 2.0
const GLOW_WIDTH:    float = 6.0
const DURATION:      float = 0.45
const REGEN_FRAMES:  int   = 2      # regenerate bolt shape every N frames

# ─────────────────────────────────────────
#  Public
# ─────────────────────────────────────────
var bolt_color: Color = Color(0.5, 1.0, 0.6)

# ─────────────────────────────────────────
#  Internal
# ─────────────────────────────────────────
var _from:      Vector2  = Vector2.ZERO
var _to:        Vector2  = Vector2.ZERO
var _active:    bool     = false
var _elapsed:   float    = 0.0
var _callback:  Callable
var _bolts:     Array    = []   # Array of Array[Vector2] — global positions


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	# Regenerate bolt shape every REGEN_FRAMES for flicker effect
	if Engine.get_process_frames() % REGEN_FRAMES == 0:
		_generate_bolts()

	queue_redraw()

	if _elapsed >= DURATION:
		_active = false
		queue_redraw()
		if _callback.is_valid():
			_callback.call()


func _draw() -> void:
	if not _active or _bolts.is_empty():
		return

	var life_pct = 1.0 - clampf(_elapsed / DURATION, 0.0, 1.0)

	for i in range(_bolts.size()):
		var global_pts: Array[Vector2] = _bolts[i]
		if global_pts.is_empty():
			continue

		# Convert global → local for _draw()
		var local_pts = PackedVector2Array()
		for pt in global_pts:
			local_pts.append(to_local(pt))

		# Outer glow
		draw_polyline(
			local_pts,
			Color(bolt_color.r, bolt_color.g, bolt_color.b,
				0.20 * life_pct),
			GLOW_WIDTH
		)

		# Mid glow
		draw_polyline(
			local_pts,
			Color(bolt_color.r, bolt_color.g, bolt_color.b,
				0.40 * life_pct),
			GLOW_WIDTH * 0.5
		)

		# Core — brightest, thinnest
		# Each bolt is slightly brighter than the last
		var core_alpha = clampf(
			(0.5 + 0.5 * float(i + 1) / BOLT_COUNT) * life_pct,
			0.0, 1.0
		)
		draw_polyline(
			local_pts,
			Color(bolt_color.r + 0.3, bolt_color.g + 0.1,
				bolt_color.b + 0.1, core_alpha).clamp(),
			LINE_WIDTH
		)

	# ── Impact flash at the omnitrix end ──
	var local_to = to_local(_to)
	var flash_r  = 16.0 * life_pct

	# Outer flash ring
	draw_circle(local_to, flash_r,
		Color(bolt_color.r, bolt_color.g, bolt_color.b,
			0.30 * life_pct))

	# Inner bright core
	draw_circle(local_to, flash_r * 0.45,
		Color(1.0, 1.0, 1.0, 0.80 * life_pct))

	# ── Origin flash at the card end ──
	var local_from = to_local(_from)
	draw_circle(local_from, 6.0 * life_pct,
		Color(bolt_color.r, bolt_color.g, bolt_color.b,
			0.25 * life_pct))


# ─────────────────────────────────────────
#  Public API
# ─────────────────────────────────────────
func shoot(from: Vector2, to: Vector2, on_complete: Callable) -> void:
	_from     = from
	_to       = to
	_callback = on_complete
	_elapsed  = 0.0
	_active   = true
	_generate_bolts()
	queue_redraw()


# ─────────────────────────────────────────
#  Bolt generation
# ─────────────────────────────────────────
func _generate_bolts() -> void:
	_bolts.clear()

	var base_dir  = (_to - _from).normalized()
	var perp      = base_dir.rotated(PI * 0.5)
	var total_len = _from.distance_to(_to)

	for b in range(BOLT_COUNT):
		var pts: Array[Vector2] = []

		# Slight random offset per bolt so they don't overlap perfectly
		var bolt_offset = perp * randf_range(-4.0, 4.0)

		for i in range(SEGMENTS + 1):
			var t    = float(i) / float(SEGMENTS)
			var base = _from.lerp(_to, t) + bolt_offset

			# Jitter perpendicular to the bolt direction
			# Envelope: peaks at t=0.5, tapers to 0 at endpoints
			# so bolts always connect cleanly at source and target
			var envelope       = sin(t * PI)
			var jitter_amount  = JITTER * envelope

			# Add extra chaos in the middle segment
			if t > 0.3 and t < 0.7:
				jitter_amount *= 1.4

			var offset = perp * randf_range(-jitter_amount, jitter_amount)
			pts.append(base + offset)

		_bolts.append(pts)


# ─────────────────────────────────────────
#  Cleanup
# ─────────────────────────────────────────
func _exit_tree() -> void:
	_active = false
