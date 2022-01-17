extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func on_StartButton_pressed():
	var _dontcare = get_tree().change_scene("res://run.tscn")
