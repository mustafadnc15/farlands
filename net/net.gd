# STUB — replaced by the net agent in M1; keep these signatures.
## No class_name: this script is the `Net` autoload singleton.
extends Node

signal player_joined(peer_id: int, player_id: String)
signal player_left(peer_id: int, player_id: String)


func is_host() -> bool:
	return multiplayer.multiplayer_peer == null or multiplayer.is_server()


## Remote sender id of the RPC being handled, or 1 when the host called locally.
func sender_id() -> int:
	var id := multiplayer.get_remote_sender_id()
	return 1 if id == 0 else id


func peer_to_player(_peer_id: int) -> String:
	return ""


func player_node(_peer_id: int) -> Node3D:
	return null
