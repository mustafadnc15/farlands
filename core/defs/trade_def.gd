## Trader entry: item, buy and sell price, daily stock (-1 = unlimited).
class_name TradeDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var item: StringName = &""
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var daily_stock: int = -1
