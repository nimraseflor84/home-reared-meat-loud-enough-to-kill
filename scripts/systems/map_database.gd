class_name MapDatabase

# Welche Map gehört zu welcher Wave
static func get_map_for_wave(wave: int) -> String:
	match wave:
		1, 2:    return "proberaum"
		3, 4:    return "prison"
		5:       return "farm"
		6, 7:    return "schweinestall"
		8:       return "amerika"
		9:       return "truck"
		10:      return "tonstudio"
		11:      return "tv_studio"
		12, 13:  return "meppen"
		14, 15:  return "death_feast"
		_:       return "death_feast"

const MAP_INFO = {
	"farm": {
		"title": "Die Farm",
		"subtitle": "Irgendwo in Niedersachsen...",
	},
	"prison": {
		"title": "Das Gefaengnis",
		"subtitle": "3 Jahre wegen Laermbelaestigung",
	},
	"proberaum": {
		"title": "Der Proberaum",
		"subtitle": "Nachbarn wieder sauer...",
	},
	"schweinestall": {
		"title": "Der Schweinestall",
		"subtitle": "Riecht nach Musik",
	},
	"amerika": {
		"title": "Amerika",
		"subtitle": "Road Trip from Hell",
	},
	"truck": {
		"title": "Fahrender Truck",
		"subtitle": "270 km/h auf der A31",
	},
	"tonstudio": {
		"title": "Tonstudio Soundlodge",
		"subtitle": "Rhauderfehn, Ostfriesland...",
	},
	"tv_studio": {
		"title": "TV Studio",
		"subtitle": "Live on Air",
	},
	"meppen": {
		"title": "Meppen",
		"subtitle": "City of the Damned",
	},
	"death_feast": {
		"title": "Death Feast",
		"subtitle": "Buehne Andernach – letzte Chance!",
	},
}
