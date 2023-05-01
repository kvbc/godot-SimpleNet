@tool
extends EditorPlugin

func _enter_tree ():
	add_autoload_singleton("SimpleNet", "res://addons/SimpleNet/SimpleNet.gd")
