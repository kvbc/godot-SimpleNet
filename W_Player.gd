extends Object
class_name Player

#
# [Public]
#

signal OnMasterMoved (dirs: Array)

#
# [Private]
#

var _peer: int
var _node: Node2D
var _newPos: Vector2

func _init (parent, peer: int) -> void:
	_peer = peer
	
	_node = preload("res://W_Player.tscn").instantiate()
	_node.name = str(peer)
	
	var middleware = func ():
		_node.OnReady.connect(func ():
			var isMaster = (peer == _node.multiplayer.get_unique_id())
			_node.get_node("PeerLabel").text = str(peer) + "\n" + ("Master" if isMaster else "Puppet")	
			
			if isMaster:
				_node.OnProcess.connect(func (delta: float) -> void:
					var dirs = []
					if Input.is_key_pressed(KEY_W): dirs.append("up")
					if Input.is_key_pressed(KEY_S): dirs.append("down")
					if Input.is_key_pressed(KEY_A): dirs.append("left")
					if Input.is_key_pressed(KEY_D): dirs.append("right")
					OnMasterMoved.emit(dirs)
				)
				
			_node.OnProcess.connect(func (delta: float) -> void:
				if _newPos != null:
					_node.position = _node.position.lerp(_newPos, 0.35)
			)
		)
		
	SimpleNet.Wrap(_node, parent, middleware)

#
# [Public]
#

func Destroy () -> void:
	_node.queue_free()

func GetPeer () -> int:
	return _peer

#
# [Public] Net
#

func Net_OnClientSent (cPacket: Dictionary, cPacketType: String) -> void:
	# simulate locally on clients
	if not _node.multiplayer.is_server():
		Net_OnClientReceived(
			Net_OnServerReceived(cPacket, cPacketType),
			cPacketType
		)

func Net_OnServerReceived (cPacket: Dictionary, cPacketType: String) -> Dictionary:
	var sData = {}

	if cPacket.dirs.has("left")  : _node.position.x -= 10
	if cPacket.dirs.has("right") : _node.position.x += 10
	if cPacket.dirs.has("up")    : _node.position.y -= 10
	if cPacket.dirs.has("down")  : _node.position.y += 10
	sData.pos = _node.position

	return sData

func Net_OnClientReceived (sPacket: Dictionary, sPacketType: String) -> void:
	_newPos = sPacket.pos
