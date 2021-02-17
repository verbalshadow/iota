extends HTTPClient
class_name IotaClient

signal next_complete
signal pool_empty

var pool = []
var headers = [
	"User-Agent: Iota/0.2.0 (Godot)",
	"Accept: */*"
	]

func add(uri):
	var found = false
	for item in pool:
		if uri.meta.url_hash == item.meta.url_hash:
			found = true
	if !found:
		pool.append(uri)

func add_url(url, method, body = null, path = null):
	var found = false
	var test_hash = hash(url)
	for item in pool:
		if test_hash == item.meta.url_hash:
			found = true
	if !found:
		var addme = URI.new()
		addme.from_url(url, method, body, path)
		pool.append(addme)

func remove(url):
	var test_hash = hash(url)
	for item in pool:
		if test_hash == item.meta.url_hash:
			pool.erase(item)

func next():
	var err = null
	print(pool.size())
	if pool.size() > 0:
		var item = pool.pop_front()
		if get_status() == HTTPClient.STATUS_DISCONNECTED:
			var realport = -1
			if item.port !=80 or item.port != 443:
				realport = item.port
			err = connect_to_host(item.host, realport, true) # Connect to host/port.
			assert(err == OK) # Make sure connection was OK
			# Wait until resolved and connected.
			while get_status() == HTTPClient.STATUS_CONNECTING or get_status() == HTTPClient.STATUS_RESOLVING:
				poll()
				print("Connecting...")
				OS.delay_msec(500)
			print(get_status())
		assert(get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect
		demand(item)
		connect("next_complete", self, "next_complete")
	
	else:
		close()
		emit_signal("pool_empty")

func demand(uri):
	var err = null
	match uri.meta.method:
		HTTPClient.METHOD_GET: 
			err = request(HTTPClient.METHOD_GET, uri.path, headers, query_string_from_dict(uri.query))
		HTTPClient.METHOD_PUT: 
			err = request(HTTPClient.METHOD_PUT, uri.path, headers, uri.body)
		HTTPClient.METHOD_POST: 
			err = request(HTTPClient.METHOD_POST, uri.path, headers, uri.body)
		HTTPClient.METHOD_PATCH: 
			err = request(HTTPClient.METHOD_PATCH, uri.path, headers, uri.body)
		HTTPClient.METHOD_DELETE: 
			err = request(HTTPClient.METHOD_DELETE, uri.path, headers, uri.body)
		HTTPClient.METHOD_HEAD: 
			err = request(HTTPClient.METHOD_HEAD, uri.path, headers, query_string_from_dict(uri.query))
		HTTPClient.METHOD_OPTIONS: 
			err = request(HTTPClient.METHOD_OPTIONS, uri.path, headers, query_string_from_dict(uri.query))
		HTTPClient.METHOD_TRACE: 
			err = request(HTTPClient.METHOD_TRACE, uri.path, headers, query_string_from_dict(uri.query))
		HTTPClient.METHOD_CONNECT: 
			err = request(HTTPClient.METHOD_CONNECT, uri.path, headers, query_string_from_dict(uri.query))
	assert(err == OK) # Make sure all is OK.
	
	while get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		poll()
		print("Requesting...")
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")

	assert(get_status() == HTTPClient.STATUS_BODY or get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.

#	print("response? ", has_response()) # Site might not have a response.
	
	if has_response():
		# If there is a response...
		
#		var new_headers = get_response_headers_as_dictionary() # Get response headers.
#		print("code: ", get_response_code()) # Show response code.
#		print("**headers:\\n", new_headers) # Show headers.
		
		# Getting the HTTP Body
		
#		if is_response_chunked():
#			# Does it use chunks?
#			print("Response is Chunked!")
#		else:
#			# Or just plain Content-Length
#			var bl = get_response_body_length()
#			print("Response Length: ", bl)
#
		# This method works for both anyway
		
		var rb = PoolByteArray() # Array that will hold the data.
		
		while get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			poll()
			var chunk = read_response_body_chunk() # Get a chunk.
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer.
	
		# Done!
		var headers = get_response_headers_as_dictionary()
		if headers.has("Content-Type"):
			if MediaType.APPLICATION_JSON in headers["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.APPLICATION_XML in headers["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.TEXT_PLAIN in headers["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.TEXT_HTML in headers["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.IMAGE_PNG in headers["Content-Type"]:
				save_image(uri, rb)
			elif MediaType.IMAGE_JPEG in headers["Content-Type"]:
				save_image(uri, rb)
			elif MediaType.IMAGE_WEBP in headers["Content-Type"]:
				save_image(uri, rb)
#			elif MediaType.IMAGE_WEBA in headers["Content-Type"]:
#				save_image(uri, rb)
#			elif MediaType.VIDEO_WEBM in headers["Content-Type"]:
#				save_image(uri, rb)

func next_complete():
	next()

func save_image(uri, content):
	var file = File.new()
	file.open(uri.meta.save_path, File.WRITE)
	file.store_buffer(content)
	file.close()
	emit_signal("next_complete")
	
func save_text(uri, content):
	var file = File.new()
	var step = content.get_string_from_utf8()
	var f_error = file.open(uri.meta.save_path, File.WRITE)
	if f_error == OK:
		file.store_line(step)
	else:
		print("error: unable to save %s file" % uri.meta.save_path)
	file.close()
	emit_signal("next_complete")

"""
Class for URIs with a few extras to simplify usage
"""
class URI:
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
	
	func fill(scheme, host, port, path = "", query = {}, method = HTTPClient.METHOD_GET, body = null, save_path = null):
		meta.url_hash = hash(scheme+"://"+host+":"+port+path+query)
		meta.method = method
		meta.save_path = save_path
		body = body
		scheme = scheme
		host = host
		port = port
		path = path
		query = query

	func from_url(url, method = HTTPClient.METHOD_GET, body = null, save_path = null):
		meta.url_hash = hash(url)
		meta.method = method
		meta.save_path = save_path
		body = body

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

		if port < 0:
			match scheme:
				"https": port = 443
				"http": port = 80
				_: port = 80

"""
Media type class to defined constants
"""
class MediaType:
	const APPLICATION_JSON = "application/json"
	const APPLICATION_XML = "application/xml"
	const TEXT_PLAIN = "text/plain"
	const TEXT_HTML = "text/html"
	const IMAGE_PNG = "image/png"
	const IMAGE_JPEG = "image/jpeg"
	const IMAGE_WEBP = "image/webp"
	const IMAGE_WEBA = "audio/webm"
	const VIDEO_WEBM = "video/webm"
