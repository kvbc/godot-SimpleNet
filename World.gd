extends Node2D

#
# [Public]
#

signal OnPlayerCreated (plr: Player)

#
# [Private]
#

var _players = []

func _input (event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_H:
				var peer = ENetMultiplayerPeer.new()
				peer.create_server(9191, 2)
				multiplayer.multiplayer_peer = peer
			elif event.keycode == KEY_J:
				var peer = ENetMultiplayerPeer.new()
				peer.create_client("localhost", 9191)
				multiplayer.multiplayer_peer = peer

func _ready ():
	(func ():
		var onClientSend = func (cPacket: Dictionary, cPacketType: String) -> void:
			var cPeer = multiplayer.get_unique_id()
			var plr = getPlayer(cPeer)
			if plr != null:
				plr.Net_OnClientSent(cPacket, cPacketType)
			
		var onServerReceive = func (cPeer: int, cPacket: Dictionary, cPacketType: String) -> Dictionary:
			var plr = getPlayer(cPeer)
			return plr.Net_OnServerReceived(cPacket, cPacketType)
		
		var onClientReceive = func (cPeer: int, sPacket: Dictionary, sPacketType: String) -> void:
			var plr = getPlayer(cPeer)
			plr.Net_OnClientReceived(sPacket, sPacketType)
		
		var send = SimpleNet.Register(
			"player",
			onClientSend,
			onServerReceive,
			onClientReceive
		)
		
		OnPlayerCreated.connect(func (plr: Player) -> void:
			plr.OnMasterMoved.connect(func (dirs: Array) -> void:
				send.call({
					"dirs": dirs
				})	
			)
		)
	).call()
	
	createPlayer(1)
	
	multiplayer.connected_to_server.connect(func ():
		var peer = multiplayer.get_unique_id()
		deletePlayer(1)
		createPlayer(peer)
		print("[%d] connected to server" % peer)
	)

	multiplayer.peer_connected.connect(func (peer: int):
		if multiplayer.is_server():
			createPlayer(peer)
		else:
			createPlayer(peer)
		print("[%d] %d connected" % [
			multiplayer.get_unique_id(),
			peer
		])
	)

func deletePlayer (peer: int) -> void:
	var plr = getPlayer(peer)
	plr.Destroy()
	_players.erase(plr)

func createPlayer (peer: int) -> void:
	var plr = Player.new($Players, peer)
	_players.append(plr)
	OnPlayerCreated.emit(plr)

func getPlayer (peer: int) -> Player:
	for plr in _players:
		if plr.GetPeer() == peer:
			return plr
	return null
