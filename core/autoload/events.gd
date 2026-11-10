## Global gameplay event bus (contracts §10). Signals only: no state, no methods.
## No class_name: this script is the `Events` autoload singleton.
## Fired on every peer unless marked; `ui_toast` is local only.
extends Node

@warning_ignore_start("unused_signal")
signal item_picked_up(peer_id: int, item_id: StringName, count: int)
signal item_crafted(peer_id: int, item_id: StringName)
signal tool_used(peer_id: int, tool_type: StringName, hit_entity: int)
signal node_hit(entity_id: int)
signal node_depleted(entity_id: int)
signal piece_placed(entity_id: int, piece_id: StringName)
signal piece_completed(entity_id: int, piece_id: StringName)
signal piece_removed(entity_id: int)
signal crop_planted(entity_id: int)
signal crop_harvested(entity_id: int)
signal player_damaged(peer_id: int, amount: float)
signal player_died(peer_id: int)
signal player_respawned(peer_id: int)
signal player_ate(peer_id: int, item_id: StringName)
signal trade_done(peer_id: int, item_id: StringName, count: int, bought: bool)
signal coins_changed(total: int)
signal worker_hired(entity_id: int, job_id: StringName)
signal worker_job_changed(entity_id: int, job_id: StringName)
signal ui_toast(text: String)
@warning_ignore_restore("unused_signal")
