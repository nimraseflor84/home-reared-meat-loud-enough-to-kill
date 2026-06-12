## WiFi-Check-Hilfsfunktionen für Multiplayer.
## Multiplayer auf Android ist nur über WLAN erlaubt.

static func is_wifi_connected() -> bool:
	# Auf Desktop immer true (PC-Multiplayer braucht keine WLAN-Pflicht)
	if OS.has_feature("pc"):
		return true
	# Android / iOS: prüfen ob Netzwerk verfügbar ist.
	# Godot 4 hat keinen direkten WiFi-Status-API – wir nutzen eine heuristische
	# Prüfung über die IP-Adresse (WLAN hat üblicherweise 192.168.x.x oder 10.x.x.x).
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return true
	return false

static func show_no_wifi_dialog(parent: Node) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Kein WLAN"
	dialog.dialog_text = "Multiplayer ist nur über WLAN verfügbar.\nBitte verbinde dich mit einem WLAN-Netzwerk."
	parent.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
