extends Resource
class_name URI

"""
Class for URIs with a few extras to simplify usage
"""
var scheme
var host
var port = -1
var path
var query = {}
var body = null
var meta = {
	"method" : null,
	"url_hash" : null,
	"save_path" : null
}

func fill(sch, hst, prt, pth = "", qry = "", mthd = HTTPClient.METHOD_GET, bdy = null, sv_pth = null):
	meta.url_hash = hash(sch+"://"+hst+":"+str(prt)+pth+qry)
	meta.method = mthd
	meta.save_path = sv_pth
	body = bdy
	scheme = sch
	host = hst
	port = prt
	path = pth
	var query_pos = qry.find("?")
	if query_pos >= 0:
		# q: name=Bob&age=30
		var q = qry.substr(query_pos + 1, len(qry))

		# params: ["name=Bob", "age=30"]
		var params = q.split("&")

		# query: { "name": "Bob", "age": 30 }
		for i in params:
			var parts = i.split("=")
			query[parts[0]] = parts[1]


func from_url(url, mthd = HTTPClient.METHOD_GET, bdy = null, sv_pth = null):
	meta.url_hash = hash(url)
	meta.method = mthd
	meta.save_path = sv_pth
	body = bdy

	if url.begins_with("https://"):
		scheme = "https"
		url = url.trim_prefix("https://")
	elif url.begins_with("http://"):
		scheme = "http"
		url = url.trim_prefix("http://")
	else:
		scheme = "http"

	# URL should now be domain.com:port/path/?name=Bob&age=30
	var query_pos = url.find("?")
	if query_pos >= 0:
		# q: name=Bob&age=30
		var q = url.substr(query_pos + 1, len(url))

		# params: ["name=Bob", "age=30"]
		var params = q.split("&")

		# query: { "name": "Bob", "age": 30 }
		for i in params:
			var parts = i.split("=")
			query[parts[0]] = parts[1]
		
		# URL should now be domain.com:port/path/
		url = url.trim_suffix(q)

	var slash_pos = url.find("/")
	if slash_pos >= 0:
		path = url.substr(slash_pos, len(url))

		# URL should now be domain.com:port
		url = url.trim_suffix(path)

	var port_pos = url.find(":")
	if port_pos >= 0:
		port = int(url.substr(port_pos, len(url)))

		# URL should now be domain.com
		url = url.trim_suffix(port)

	# Assign remaining string to host
	host = url

#		if port < 0:
#			match scheme:
#				"https": port = 443
#				"http": port = 80
#				_: pass
