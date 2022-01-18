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
const den_image = preload("res://fox_den.png")
const thunk_sound = preload("res://Thunk.wav")

var rocks = []
var shape
var rows = []


class Scenery:
	var position = Vector2()
	var offset = Vector2(0,0)
	var type = "rock"
	# The body is stored as a RID, which is an "opaque" way to access resources.
	# With large amounts of objects (thousands or more), it can be significantly
	# faster to use RIDs compared to a high-level approach.
	var body = RID()
	
class Den:
	var position = Vector2()
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
	Physics2DServer.shape_set_data(shape, ROCK_X_GRID / 4)
	
	var xpos = get_viewport_rect().size.x

	for _i in ROCK_COUNT:
		var rock = Scenery.new()
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
			xpos,
			nexty() * ROCK_Y_GRID
		)
		xpos += ROCK_X_GRID
		var transform2d = Transform2D()
		transform2d.origin = rock.position
		Physics2DServer.body_set_state(rock.body, Physics2DServer.BODY_STATE_TRANSFORM, transform2d)

		rocks.push_back(rock)

	var den = Scenery.new()
	den.body = Physics2DServer.body_create()
	Physics2DServer.body_set_space(den.body, get_world_2d().get_space())
	Physics2DServer.body_add_shape(den.body, shape)
	Physics2DServer.body_set_collision_layer(den.body, 0)
	den.type = "den"
	den.position = Vector2( xpos, 0 )
	den.offset = Vector2( den_image.get_size().x * 4 / 5, den_image.get_size().y * 4 / 5 )
	var transform2d = Transform2D()
	transform2d.origin = den.position + den.offset
	Physics2DServer.body_set_state(den.body, Physics2DServer.BODY_STATE_TRANSFORM, transform2d)
	Common.den_body = den.body
	rocks.push_back( den )

func _process(_delta):
	# Order the CanvasItem to update every frame.
	update()


func _physics_process(delta):
	var transform2d = Transform2D()
	#var offset = floor( get_viewport_rect().size.x / ROCK_X_GRID ) * ROCK_X_GRID
	for rock in rocks:
		rock.position.x -= ROCK_SPEED * delta
		if rock.type == "den" && rock.position.x + den_image.get_size().x < get_viewport_rect().size.x:
			rock.position.x = get_viewport_rect().size.x - den_image.get_size().x
		transform2d.origin = rock.position + rock.offset

		Physics2DServer.body_set_state(rock.body, Physics2DServer.BODY_STATE_TRANSFORM, transform2d)


# Instead of drawing each rock individually in a script attached to each rock,
# we are drawing *all* the rocks at once here.
func _draw():
	var offset = -rock_image.get_size() * 0.5
	for rock in rocks:
		if rock.type == "rock":
			draw_texture(rock_image, rock.position + offset)
		if rock.type == "den":
			draw_texture(den_image, rock.position)


# Perform cleanup operations (required to exit without error messages in the console).
func _exit_tree():
	for rock in rocks:
		Physics2DServer.free_rid(rock.body)

	Physics2DServer.free_rid(shape)
	rocks.clear()
