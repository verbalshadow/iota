extends Node2D

func _ready():
	var http = IotaClient.new()
	http.add("https://api.godsunchained.com/v0/match?page=1&perPage=10000&start_time=1514764800-1611203726", HTTPClient.METHOD_GET, null, "user://match0.json")
	http.add("https://api.godsunchained.com/v0/match?page=1&perPage=10000&start_time=1609459200-1611203726", HTTPClient.METHOD_GET, null, "user://match1.json")
	http.next()
