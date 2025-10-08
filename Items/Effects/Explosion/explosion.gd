extends Node3D

@onready var anim_player: AnimationPlayer = $Explosion_Animation

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("start_animation"):
		anim_player.play("Init")
