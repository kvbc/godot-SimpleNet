extends Node

#
# [Private]
#

class PacketHandler:
	# [Private]
	var _onServerReceive: Callable
	var _onClientReceive: Callable

	func _init (
		onServerReceive: Callable,
		onClientReceive: Callable
	) -> void:
		_onServerReceive = onServerReceive
		_onClientReceive = onClientReceive

	# [Public]
	func GetOnServerReceiveCallback (): return _onServerReceive
	func GetOnClientReceiveCallback (): return _onClientReceive

var _packetHandlers = {} # Dictionary(packetType -> PacketHandler)

@rpc("any_peer", "call_local") func _onServerReceive (cPacket: Dictionary, cPacketType: String) -> void:
	var packetHandler = _packetHandlers[cPacketType]
	var cPeer = multiplayer.get_remote_sender_id()
	var sPacket: Dictionary = packetHandler.GetOnServerReceiveCallback().call(cPeer, cPacket, cPacketType)
	self.rpc("_onClientReceive", cPeer, sPacket, cPacketType)

@rpc("any_peer", "call_local") func _onClientReceive (cPeer: int, sPacket: Dictionary, sPacketType: String) -> void:
	var packetHandler = _packetHandlers[sPacketType]
	packetHandler.GetOnClientReceiveCallback().call(cPeer, sPacket, sPacketType)

#
# [Public]
#

func IsRegistered (packetType: String) -> bool:
	return _packetHandlers.has(packetType)

func Register (
	packetType: String,
	onClientSend: Callable,
	onServerReceive: Callable,
	onClientReceive: Callable
) -> Callable:
	if not IsRegistered(packetType):
		_packetHandlers[packetType] = PacketHandler.new(onServerReceive, onClientReceive)
		return func (cPacket: Dictionary) -> void:
			onClientSend.call(cPacket, packetType)
			self.rpc_id(1, "_onServerReceive", cPacket, packetType)
			
	return func (cPacket: Dictionary) -> void:
		printerr("error")
		push_error("error")

static func Wrap (
	node: Node,
	parent = null,
	middleware: Callable = func():pass
) -> void:
	node.set_script(preload("res://addons/SimpleNet/_WrappedNode.gd"))
	
	middleware.call()
	
	if parent != null:
		parent.add_child(node)
