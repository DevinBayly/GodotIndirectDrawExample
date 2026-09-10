extends Node3D

@onready var meshOpt = $GDExample
@onready var mesh = $MeshInstance3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(meshOpt)
	var jsonRes = meshOpt.calculate_meshlets(mesh)
	print(jsonRes)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
