# ReseauManager.gd
extends RefCounted
class_name ReseauManager

enum SubID {
	ROLL_DICE = 1,
	PAY_JAIL = 2,
	USE_CARD = 3,
	BUY_PROPERTY = 4,
	BUILD_HOUSE = 5,
	END_TURN = 6,
	READY_NEXT_TURN = 7
}

# Envoie une action au serveur
static func _send_action(sub_id: int, extra_data: Dictionary = {}):
	var paquet = {
		"mainID": 3,
		"subID": sub_id,
		"clientID": Global.my_client_id,
		"data": { "matchID": Global.current_match_id }
	}
	paquet.data.merge(extra_data)
	Reseau.send_data(paquet)

static func roll_dice(): _send_action(SubID.ROLL_DICE)
static func pay_jail(): _send_action(SubID.PAY_JAIL)
static func use_jail_card(card_id: int): _send_action(SubID.USE_CARD, {"cardID": card_id})
static func buy_property(prop_id: int): _send_action(SubID.BUY_PROPERTY, {"propertyID": prop_id})
static func end_turn(): _send_action(SubID.END_TURN)
static func ready_next_turn(): _send_action(SubID.READY_NEXT_TURN)
static func build_house(prop_id: int, total_houses: int): _send_action(SubID.BUILD_HOUSE,{"propertyID": prop_id, "totalHouses":total_houses})
