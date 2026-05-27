# MonopolyLogic.gd
extends RefCounted
class_name MonopolyLogic

enum CaseType { PROPERTY, STATION, UTILITY, TAX, CHANCE, COMMUNITY, START, JAIL_VISIT, PARKING, GO_TO_JAIL }

# Compte combien de propriétés d'un type (station/utility) possède un joueur
static func count_owned_type(client_id: int, type_string: String) -> int:
	var count = 0
	for prop_id in Global.proprietes_joueurs:
		if Global.proprietes_joueurs[prop_id] == client_id:
			var data = GameData.PROPERTIES.get(prop_id, {})
			if data.get("type") == type_string:
				count += 1
	return count

# Calcule le loyer selon le type (propriété, gare, compagnie)
static func get_rent(property_id: int, nb_houses: int, dice_total: int, owner_id: int) -> int:
	var data = GameData.PROPERTIES.get(property_id)
	if not data: return 0

	match data.get("type", ""):
		"property":
			var rents = [
				data.get("rent_base", 0), data.get("rent_1h", 0), data.get("rent_2h", 0),
				data.get("rent_3h", 0), data.get("rent_4h", 0), data.get("rent_hotel", 0)
			]
			return rents[clamp(nb_houses, 0, 5)]
		"station":
			var nb_stations = count_owned_type(owner_id, "station")
			return 25 << int(clamp(nb_stations - 1, 0, 3))
		"utility":
			var nb_utilities = count_owned_type(owner_id, "utility")
			var multiplier = 10 if nb_utilities >= 2 else 4
			return multiplier * dice_total
	return 0

# Calcule la nouvelle position après un déplacement et détecte le passage par Départ
static func calculate_move(current_pos: int, dice_sum: int) -> Dictionary:
	var total_pos = current_pos + dice_sum
	var new_pos = total_pos % 40
	var passed_start = total_pos >= 40
	return { "new_pos": new_pos, "passed_start": passed_start }

# Retourne le type de case (enum CaseType) à partir de la position
static func resolve_case_type(pos: int) -> int:
	var data = GameData.PROPERTIES.get(pos, {})
	match data.get("type"):
		"property": return CaseType.PROPERTY
		"station": return CaseType.STATION
		"utility": return CaseType.UTILITY
		"tax": return CaseType.TAX
		"card_chance": return CaseType.CHANCE
		"card_community": return CaseType.COMMUNITY
		"special":
			match data.get("effect"):
				"go_to_jail": return CaseType.GO_TO_JAIL
				"collect_start": return CaseType.START
				"free_parking": return CaseType.PARKING
				"visit_jail": return CaseType.JAIL_VISIT
	return CaseType.JAIL_VISIT

# Récupère l'effet d'une carte Chance ou Caisse de Communauté
static func get_card_effect(card_id: int) -> Dictionary:
	var card_data : Dictionary
	if card_id >= 100 and card_id < 200:
		card_data = GameData.CHANCE_CARDS.get(card_id, {})
	else:
		card_data = GameData.COMMUNITY_CHEST_CARDS.get(card_id, {})

	if card_data.is_empty():
		return {"type": "none"}

	return {
		"effect": card_data.get("effect", ""),
		"amount": card_data.get("amount", 0),
		"target_id": card_data.get("target_id", -1),
		"card_id": card_id
	}
	
static func cleanup_player(client_id:int):
	Global.positions_joueurs.erase(client_id)
	
	for property_id in Global.proprietes_joueurs.keys():
		if Global.proprietes_joueurs[property_id] == client_id:
			Global.proprietes_joueurs.erase(property_id)
			Global.maisons_proprietes.erase(property_id)
	Global.etat_prison.erase(client_id)
	Global.cartes_prison.erase(client_id)
	
	Global.joueurs.erase(client_id)
	Global.lobby_players = Global.lobby_players.filter(func(p): return p.get("clientID") != client_id)
	
