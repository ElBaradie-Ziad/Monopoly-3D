# GameData.gd
extends Node

const PROPERTIES = {
	# 0
	0: {
		"name": "Départ",
		"type": "special",
		"group": "start",
		"color": Color(1.0, 0.85, 0.0),
		"effect": "collect_start",
		"amount": 200,
		"popup": null
	},

	# 1
	1: {
		"name": "Boulevard de Belleville",
		"type": "property",
		"group": "brown",
		"color": Color(0.55, 0.27, 0.07),
		"price": 60,
		"rent_base": 2,
		"rent_1h": 10,
		"rent_2h": 30,
		"rent_3h": 90,
		"rent_4h": 160,
		"rent_hotel": 250,
		"house_cost": 50,
		"hotel_cost": 50
	},

	# 2 - Caisse de Communauté
	2: {
		"name": "Caisse de Communauté",
		"type": "card_community",
		"group": "community",
		"color": Color(0.0, 0.6, 0.0),
		"effect": "draw_community",          # Le Id de la carte sera donnés par le serveur.
		"popup": "community_card"
	},

	# 3
	3: {
		"name": "Rue Lecourbe",
		"type": "property",
		"group": "brown",
		"color": Color(0.55, 0.27, 0.07),
		"price": 60,
		"rent_base": 4,
		"rent_1h": 20,
		"rent_2h": 60,
		"rent_3h": 180,
		"rent_4h": 320,
		"rent_hotel": 450,
		"house_cost": 50,
		"hotel_cost": 50
	},

	# 4
	4: {
		"name": "Impôt sur le revenu",
		"type": "tax",
		"group": "tax",
		"color": Color(0.4, 0.4, 0.4),
		"price": 200,
		"effect": "income_tax",
		"popup": "tax_popup"
	},

	# 5
	5: {
		"name": "Gare Montparnasse",
		"type": "station",
		"group": "station",
		"color": Color(0.3, 0.3, 0.3),
		"price": 200,
		"rent_base": 25,
		"rent_1station": 50,
		"rent_2stations": 100,
		"rent_3stations": 200,
		"rent_4stations": 200,
		"house_cost": 0,
		"hotel_cost": 0
	},

	# 6
	6: {
		"name": "Rue de Vaugirard",
		"type": "property",
		"group": "light_blue",
		"color": Color(0.0, 0.75, 1.0),
		"price": 100,
		"rent_base": 6,
		"rent_1h": 30,
		"rent_2h": 90,
		"rent_3h": 270,
		"rent_4h": 400,
		"rent_hotel": 550,
		"house_cost": 50,
		"hotel_cost": 50
	},

	# 7 - Chance
	7: {
		"name": "Chance",
		"type": "card_chance",
		"group": "chance",
		"color": Color(1.0, 0.55, 0.0),
		"effect": "draw_chance",   # ID de la carte chance donnée par serveur. 
		"popup": "chance_card"
	},

	# 8
	8: {
		"name": "Rue de Courcelles",
		"type": "property",
		"group": "light_blue",
		"color": Color(0.0, 0.75, 1.0),
		"price": 100,
		"rent_base": 6,
		"rent_1h": 30,
		"rent_2h": 90,
		"rent_3h": 270,
		"rent_4h": 400,
		"rent_hotel": 550,
		"house_cost": 50,
		"hotel_cost": 50
	},

	# 9
	9: {
		"name": "Avenue de la République",
		"type": "property",
		"group": "light_blue",
		"color": Color(0.0, 0.75, 1.0),
		"price": 120,
		"rent_base": 8,
		"rent_1h": 40,
		"rent_2h": 100,
		"rent_3h": 300,
		"rent_4h": 450,
		"rent_hotel": 600,
		"house_cost": 50,
		"hotel_cost": 50
	},

	# 10 - Prison (visite)
	10: {
		"name": "Prison (visite)",
		"type": "special",
		"group": "jail",
		"color": Color(0.2, 0.2, 0.2),
		"effect": "visit_jail",
		"popup": null
	},

	# 11
	11: {
		"name": "Boulevard de la Vilette",
		"type": "property",
		"group": "purple",
		"color": Color(0.6, 0.2, 0.8),
		"price": 140,
		"rent_base": 10,
		"rent_1h": 50,
		"rent_2h": 150,
		"rent_3h": 450,
		"rent_4h": 625,
		"rent_hotel": 750,
		"house_cost": 100,
		"hotel_cost": 100
	},

	# 12 - Compagnie de distribution d'eau
	12: {
		"name": "Compagnie de distribution d'eau",
		"type": "utility",
		"group": "utility",
		"color": Color(0.0, 0.5, 0.8),
		"price": 150,
		"rent_base": 4,
		"rent_multiplier": 10,
		"house_cost": 0,
		"hotel_cost": 0
	},

	# 13
	13: {
		"name": "Avenue de Neuilly",
		"type": "property",
		"group": "purple",
		"color": Color(0.6, 0.2, 0.8),
		"price": 140,
		"rent_base": 10,
		"rent_1h": 50,
		"rent_2h": 150,
		"rent_3h": 450,
		"rent_4h": 625,
		"rent_hotel": 750,
		"house_cost": 100,
		"hotel_cost": 100    
	},

	# 14
	14: {
		"name": "Rue de Paradis",
		"type": "property",
		"group": "purple",
		"color": Color(0.6, 0.2, 0.8),
		"price": 160,
		"rent_base": 12,
		"rent_1h": 60,
		"rent_2h": 180,
		"rent_3h": 500,
		"rent_4h": 700,
		"rent_hotel": 900,
		"house_cost": 100,
		"hotel_cost": 100
	},

	# 15
	15: {
		"name": "Gare de Lyon",
		"type": "station",
		"group": "station",
		"color": Color(0.3, 0.3, 0.3),
		"price": 200,
		"rent_base": 25,
		"rent_1station": 50,
		"rent_2stations": 100,
		"rent_3stations": 200,
		"rent_4stations": 200,
		"house_cost": 0,
		"hotel_cost": 0
	},

	# 16
	16: {
		"name": "Avenue Mozart",
		"type": "property",
		"group": "orange",
		"color": Color(1.0, 0.55, 0.0),
		"price": 180,
		"rent_base": 14,
		"rent_1h": 70,
		"rent_2h": 200,
		"rent_3h": 550,
		"rent_4h": 750,
		"rent_hotel": 950,
		"house_cost": 100,
		"hotel_cost": 100
	},

	# 17
	17: {
			"name": "Caisse de Communauté",
			"type": "card_community",
			"group": "community",
			"color": Color(0.0, 0.6, 0.0),
			"effect": "draw_community",
			"popup": "community_card"
		},

	18: {
		"name": "Boulevard Saint-Michel",
		"type": "property",
		"group": "orange",
		"color": Color(1.0, 0.55, 0.0),
		"price": 180,
		"rent_base": 14,
		"rent_1h": 70,
		"rent_2h": 200,
		"rent_3h": 550,
		"rent_4h": 750,
		"rent_hotel": 950,
		"house_cost": 100,
		"hotel_cost": 100
	},

	# 19
	19: {
		"name": "Place Pigalle",
		"type": "property",
		"group": "orange",
		"color": Color(1.0, 0.55, 0.0),
		"price": 200,
		"rent_base": 16,
		"rent_1h": 80,
		"rent_2h": 220,
		"rent_3h": 600,
		"rent_4h": 800,
		"rent_hotel": 1000,
		"house_cost": 100,
		"hotel_cost": 100
	},


	# 20
	20: {
		"name": "Parc gratuit",
		"type": "special",
		"group": "park",
		"color": Color(0.0, 0.6, 0.0),
		"effect": "free_parking",
		"popup": null
	},

	# 21
	21: {
		"name": "Avenue Matignon",
		"type": "property",
		"group": "red",
		"color": Color(0.8, 0.1, 0.1),
		"price": 220,
		"rent_base": 18,
		"rent_1h": 90,
		"rent_2h": 250,
		"rent_3h": 700,
		"rent_4h": 875,
		"rent_hotel": 1050,
		"house_cost": 150,
		"hotel_cost": 150
	},


	22: {
		"name": "Chance",
		"type": "card_chance",
		"group": "chance",
		"color": Color(1.0, 0.55, 0.0),
		"effect": "draw_chance",
		"popup": "chance_card"
	},

	# 22
	23: {
		"name": "Boulevard Malesherbes",
		"type": "property",
		"group": "red",
		"color": Color(0.8, 0.1, 0.1),
		"price": 220,
		"rent_base": 18,
		"rent_1h": 90,
		"rent_2h": 250,
		"rent_3h": 700,
		"rent_4h": 875,
		"rent_hotel": 1050,
		"house_cost": 150,
		"hotel_cost": 150
	},

	# 23
	24: {
		"name": "Avenue Henri-Martin",
		"type": "property",
		"group": "red",
		"color": Color(0.8, 0.1, 0.1),
		"price": 240,
		"rent_base": 20,
		"rent_1h": 100,
		"rent_2h": 300,
		"rent_3h": 750,
		"rent_4h": 950,
		"rent_hotel": 1100,
		"house_cost": 150,
		"hotel_cost": 150
	},

	# 25
	25: {
		"name": "Gare du Nord",
		"type": "station",
		"group": "station",
		"color": Color(0.3, 0.3, 0.3),
		"price": 200,
		"rent_base": 25,
		"rent_1station": 50,
		"rent_2stations": 100,
		"rent_3stations": 200,
		"rent_4stations": 200,
		"house_cost": 0,
		"hotel_cost": 0
	},

	# 25
	26: {
		"name": "Faubourg Saint-Honoré",
		"type": "property",
		"group": "yellow",
		"color": Color(1.0, 0.85, 0.0),
		"price": 260,
		"rent_base": 22,
		"rent_1h": 110,
		"rent_2h": 330,
		"rent_3h": 800,
		"rent_4h": 975,
		"rent_hotel": 1150,
		"house_cost": 150,
		"hotel_cost": 150
	},

	# 26
	27: {
		"name": "Place de la Bourse",
		"type": "property",
		"group": "yellow",
		"color": Color(1.0, 0.85, 0.0),
		"price": 260,
		"rent_base": 22,
		"rent_1h": 110,
		"rent_2h": 330,
		"rent_3h": 800,
		"rent_4h": 975,
		"rent_hotel": 1150,
		"house_cost": 150,
		"hotel_cost": 150
	},

	# 27

		# 28 - Compagnie de distribution de l'électricité
	28: {
		"name": "Compagnie de distribution de l'électricité",
		"type": "utility",
		"group": "utility",
		"color": Color(0.0, 0.5, 0.8),
		"price": 150,
		"rent_base": 4,
		"rent_multiplier": 10,
		"house_cost": 0,
		"hotel_cost": 0
	},

	29: {
		"name": "Rue La Fayette",
		"type": "property",
		"group": "yellow",
		"color": Color(1.0, 0.85, 0.0),
		"price": 280,
		"rent_base": 24,
		"rent_1h": 120,
		"rent_2h": 360,
		"rent_3h": 850,
		"rent_4h": 1025,
		"rent_hotel": 1200,
		"house_cost": 150,
		"hotel_cost": 150
	},


	# 30
	30: {
		"name": "Aller en Prison",
		"type": "special",
		"group": "jail",
		"color": Color(0.2, 0.2, 0.2),
		"effect": "go_to_jail",
		"popup": "go_to_jail_popup",
		"animation": "jail_animation"
	},

	# 31
	31: {
		"name": "Avenue de Breteuil",
		"type": "property",
		"group": "green",
		"color": Color(0.0, 0.6, 0.2),
		"price": 300,
		"rent_base": 26,
		"rent_1h": 130,
		"rent_2h": 390,
		"rent_3h": 900,
		"rent_4h": 1100,
		"rent_hotel": 1275,
		"house_cost": 200,
		"hotel_cost": 200
	},

	# 32
	32: {
		"name": "Avenue Foch",
		"type": "property",
		"group": "green",
		"color": Color(0.0, 0.6, 0.2),
		"price": 300,
		"rent_base": 26,
		"rent_1h": 130,
		"rent_2h": 390,
		"rent_3h": 900,
		"rent_4h": 1100,
		"rent_hotel": 1275,
		"house_cost": 200,
		"hotel_cost": 200
	},
	33: {
			"name": "Caisse de Communauté",
			"type": "card_community",
			"group": "community",
			"color": Color(0.0, 0.6, 0.0),
			"effect": "draw_community",
			"popup": "community_card"
		},


	34: {
		"name": "Boulevard des Capucines",
		"type": "property",
		"group": "green",
		"color": Color(0.0, 0.6, 0.2),
		"price": 320,
		"rent_base": 26,
		"rent_1h": 130,
		"rent_2h": 390,
		"rent_3h": 900,
		"rent_4h": 1100,
		"rent_hotel": 1275,
		"house_cost": 200,
		"hotel_cost": 200
	},

	# 34
	35: {
		"name": "Gare Saint-Lazare",
		"type": "station",
		"group": "station",
		"color": Color(0.3, 0.3, 0.3),
		"price": 200,
		"rent_base": 25,
		"rent_1station": 50,
		"rent_2stations": 100,
		"rent_3stations": 200,
		"rent_4stations": 200,
		"house_cost": 0,
		"hotel_cost": 0
	},


	# 36 - Chance
	36: {
		"name": "Chance",
		"type": "card_chance",
		"group": "chance",
		"color": Color(1.0, 0.55, 0.0),
		"effect": "draw_chance",
		"popup": "chance_card"
	},

	# 35
	37: {
		"name": "Avenue des Champs-Élysées",
		"type": "property",
		"group": "green",
		"color": Color(0.0, 0.6, 0.2),
		"price": 320,
		"rent_base": 28,
		"rent_1h": 150,
		"rent_2h": 450,
		"rent_3h": 1000,
		"rent_4h": 1200,
		"rent_hotel": 1400,
		"house_cost": 200,
		"hotel_cost": 200
	},


	# 38
	38: {
		"name": "Taxe de luxe",
		"type": "tax",
		"group": "tax",
		"color": Color(0.4, 0.4, 0.4),
		"price": 150,
		"effect": "luxury_tax",
		"popup": "tax_popup"
	},

	# 39
	39: {
		"name": "Rue de la Paix",
		"type": "property",
		"group": "dark_blue",
		"color": Color(0.0, 0.2, 0.6),
		"price": 400,
		"rent_base": 50,
		"rent_1h": 200,
		"rent_2h": 600,
		"rent_3h": 1400,
		"rent_4h": 1700,
		"rent_hotel": 2000,
		"house_cost": 200,
		"hotel_cost": 200
	}
}


# ==============================================================
#                    CARTES CHANCE (100 - 115)
# ==============================================================

const CHANCE_CARDS = {
	100: {
		"id": 100,
		"text": "Avancez jusqu'à la case Départ (collectez 200 M)",
		"effect": "move_to_start",
		"amount": 200,
		"type": "positive",
		"animation": "card_flip_positive",
		"sound": "money_positive",
		"icon": "arrow_forward"
	},
	101: {
		"id": 101,
		"text": "Erreur de la banque en votre faveur : recevez 200 M",
		"effect": "receive_money",
		"amount": 200,
		"type": "positive",
		"animation": "money_rain",
		"sound": "money_positive",
		"icon": "money_bag"
	},
	102: {
		"id": 102,
		"text": "Frais de scolarité : payez 150 M",
		"effect": "pay_money",
		"amount": -150,
		"type": "negative",
		"animation": "money_loss",
		"sound": "money_negative",
		"icon": "school"
	},
	103: {
		"id": 103,
		"text": "Vous êtes libéré de prison. Cette carte peut être conservée jusqu'à ce que vous en ayez besoin.",
		"effect": "get_out_jail_free",
		"amount": 0,
		"type": "special",
		"animation": "card_keep",
		"sound": "positive",
		"icon": "key"
	},
	104: {
		"id": 104,
		"text": "Allez en prison. Ne passez pas par la case Départ. Ne touchez pas 200 M.",
		"effect": "go_to_jail",
		"amount": 0,
		"type": "negative",
		"animation": "jail_bars",
		"sound": "jail_sound",
		"icon": "prison"
	}
}

# ==============================================================
#              CARTES CAISSE DE COMMUNAUTÉ (200 - 215)
# ==============================================================

const COMMUNITY_CHEST_CARDS = {
	200: {
		"id": 200,
		"text": "Vous héritez de 100 M",
		"effect": "receive_money",
		"amount": 100,
		"type": "positive",
		"animation": "money_rain",
		"sound": "money_positive",
		"icon": "inheritance"
	},
	201: {
		"id": 201,
		"text": "Assurance vie : recevez 100 M",
		"effect": "receive_money",
		"amount": 100,
		"type": "positive",
		"animation": "money_rain",
		"sound": "money_positive",
		"icon": "insurance"
	},
	202: {
		"id": 202,
		"text": "Payez 50 M pour frais médicaux",
		"effect": "pay_money",
		"amount": -50,
		"type": "negative",
		"animation": "money_loss",
		"sound": "money_negative",
		"icon": "hospital"
	},
	203: {
		"id": 203,
		"text": "Vous êtes libéré de prison. Cette carte peut être conservée.",
		"effect": "get_out_jail_free",
		"amount": 0,
		"type": "special",
		"animation": "card_keep",
		"sound": "positive",
		"icon": "key"
	},
	204: {
		"id": 204,
		"text": "Amende pour excès de vitesse : payez 15 M",
		"effect": "pay_money",
		"amount": -15,
		"type": "negative",
		"animation": "money_loss",
		"sound": "money_negative",
		"icon": "fine"
	}
}
