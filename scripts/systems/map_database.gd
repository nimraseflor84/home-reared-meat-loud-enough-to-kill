extends RefCounted

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

# Hinweis Run #6: Die fruehere MAP_INFO-Tabelle (deutsche Titel) wurde
# entfernt. Titel und Untertitel kommen jetzt lokalisiert aus dem
# LocalizationManager: map_title(map_id) / map_subtitle(map_id).
