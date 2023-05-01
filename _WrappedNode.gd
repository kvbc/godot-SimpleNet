extends Node

#
# [Public]
#

signal OnReady
signal OnProcess (delta: float)
signal OnInput (event: InputEvent)

#
# [Private]
#

func _ready () -> void:
	OnReady.emit()

func _process (delta: float) -> void:
	OnProcess.emit(delta)

func _input (event: InputEvent) -> void:
	OnInput.emit(event)
