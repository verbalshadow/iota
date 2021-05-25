extends Node2D

func _ready():
	var http = IotaClient.new()
#	http.add_url("https://images.godsunchained.com/art2/375/1.webp", HTTPClient.METHOD_GET, null, "user://image1.webp")
#	http.add_url("https://images.godsunchained.com/art2/375/100003.webp", HTTPClient.METHOD_GET, null, "user://image2.webp")
	http.add_url("https://api.godsunchained.com/v0/match?page=1&perPage=20&start_time=1514764800-1611203726", HTTPClient.METHOD_GET, null, "user://match1.json")
	http.add_url("https://api.godsunchained.com/v0/match?page=2&perPage=20&start_time=1609459200-1611203726", HTTPClient.METHOD_GET, null, "user://match2.json")
	http.add_url("https://api.godsunchained.com/v0/match?page=3&perPage=20&start_time=1609459200-1611203726", HTTPClient.METHOD_GET, null, "user://match3.json")
	http.add_url("https://api.godsunchained.com/v0/match?page=4&perPage=20&start_time=1609459200-1611203726", HTTPClient.METHOD_GET, null, "user://match4.json")
	http.add_url("https://api.godsunchained.com/v0/match?page=5&perPage=20&start_time=1609459200-1611203726", HTTPClient.METHOD_GET, null, "user://match5.json")
	http.add_url("https://api.godsunchained.com/v0/match?page=6&perPage=20&start_time=1609459200-1611203726", HTTPClient.METHOD_GET, null, "user://match5.json")
	http.next()
	var temp = URI.new()
