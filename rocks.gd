extends Node2D
# This demo is an example of controling a high number of 2D objects with logic
# and collision without using nodes in the scene. This technique is a lot more
# efficient than using instancing and nodes, but requires more programming and
# is less visual. Bullets are managed together in the `bullets.gd` script.

const ROCK_COUNT = 64
const ROCK_SPEED = 320
const ROCK_X_GRID = 192
const ROCK_Y_GRID = 128

const SKY_HEIGHT = 2

const rock_image = preload("res://rock.png")

const thunk_sound = preload("res://Thunk.wav")

var rocks = []
var shape
var rows = []


class Rock:
	var position = Vector2()
	var speed = 1.0
	# The body is stored as a RID, which is an "opaque" way to access resources.
	# With large amounts of objects (thousands or more), it can be significantly
	# faster to use RIDs compared to a high-level approach.
	var body = RID()

func nexty():
	if rows.empty():
		for i in range( 2, floor( get_viewport_rect().size.y / ROCK_Y_GRID ) + 1 ):
			rows.push_back( i )
		rows.shuffle()
	var result = rows[-1]
	rows.pop_back()
	return result

func _ready():
	randomize()

	shape = Physics2DServer.circle_shape_create()
	# Set the collision shape's radius for each rock in pixels.
	Physics2DServer.shape_set_data(shape, 48)

	for _i in ROCK_COUNT:
		var rock = Rock.new()
		# Give each rock its own speed.
		rock.body = Physics2DServer.body_create()

		Physics2DServer.body_set_space(rock.body, get_world_2d().get_space())
		Physics2DServer.body_add_shape(rock.body, shape)
		# Don't make rocks check collision with other rocks to improve performance.
		# Their collision mask is still configured to the default value, which allows
		# rocks to detect collisions with the player.
		Physics2DServer.body_set_collision_layer(rock.body, 0)

		# Place rocks randomly on the viewport and move rocks outside the
		# play area so that they fade in nicely.
		rock.position = Vector2(
			get_viewport_rect().size.x + _i * ROCK_X_GRID,
			nexty() * ROCK_Y_GRID
		)
		rock.speed = ROCK_SPEED
		var transform2d = Transform2D()
		transform2d.origin = rock.position
		Physics2DServer.body_set_state(rock.body, Physics2DServer.BODY_STATE_TRANSFORM, transform2d)

		rocks.push_back(rock)


func _process(_delta):
	# Order the CanvasItem to update every frame.
	update()


func _physics_process(delta):
	var transform2d = Transform2D()
	#var offset = floor( get_viewport_rect().size.x / ROCK_X_GRID ) * ROCK_X_GRID
	for rock in rocks:
		rock.position.x -= rock.speed * delta
		transform2d.origin = rock.position

		Physics2DServer.body_set_state(rock.body, Physics2DServer.BODY_STATE_TRANSFORM, transform2d)


# Instead of drawing each rock individually in a script attached to each rock,
# we are drawing *all* the rocks at once here.
func _draw():
	var offset = -rock_image.get_size() * 0.5
	for rock in rocks:
		draw_texture(rock_image, rock.position + offset)


# Perform cleanup operations (required to exit without error messages in the console).
func _exit_tree():
	for rock in rocks:
		Physics2DServer.free_rid(rock.body)

	Physics2DServer.free_rid(shape)
	rocks.clear()
