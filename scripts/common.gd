extends Node

# The den is a 'rock' but assigns its body to this value so that we can
# tell the difference. This is a dumb way to do the events. I think I need
# to refactor it if we keep going on this--the rocks and the den should be
# different scenes, and the collision events should be handled in the rock
# and den respectively, not on the player.
var den_body
