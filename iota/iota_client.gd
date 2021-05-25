extends HTTPClient
class_name IotaClient

signal next_complete
signal pool_empty

var pool = []
var headers = [
	"User-Agent: Iota/0.2.1 (Godot)",
	"Accept: */*"
	]

func _init():
	connect("next_complete", self, "next", [], CONNECT_DEFERRED)

func add(uri : URI):
	var found = false
	for item in pool:
		if uri.meta.url_hash == item.meta.url_hash:
			found = true
	if !found:
		pool.append(uri)

func add_url(url : String, method, body = null, path = null):
	var found = false
	var test_hash = hash(url)
	for item in pool:
		if test_hash == item.meta.url_hash:
			found = true
	if !found:
		var addme = URI.new()
		addme.from_url(url, method, body, path)
		pool.append(addme)

func remove(url : String):
	var test_hash = hash(url)
	for item in pool:
		if test_hash == item.meta.url_hash:
			pool.erase(item)

func next():
	var err = null
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
		assert(get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect
		demand(item)
	
	else:
		close()
		emit_signal("pool_empty")

func demand(uri : URI):
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
		var hdrs = get_response_headers_as_dictionary()
		if hdrs.has("Content-Type"):
			if MediaType.APPLICATION_JSON in hdrs["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.APPLICATION_XML in hdrs["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.TEXT_PLAIN in hdrs["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.TEXT_HTML in hdrs["Content-Type"]:
				save_text(uri, rb)
			elif MediaType.IMAGE_PNG in hdrs["Content-Type"]:
				save_binary(uri, rb)
			elif MediaType.IMAGE_JPEG in hdrs["Content-Type"]:
				save_binary(uri, rb)
			elif MediaType.IMAGE_WEBP in hdrs["Content-Type"]:
				save_binary(uri, rb)
			elif MediaType.IMAGE_WEBA in hdrs["Content-Type"]:
				save_binary(uri, rb)
			elif MediaType.VIDEO_WEBM in hdrs["Content-Type"]:
				save_binary(uri, rb)
			elif MediaType.BINARY_OCTET_STREAM in hdrs["Content-Type"]:
				save_binary(uri, rb)
			else:
				print("I Don't know this %s: Pretending it is a binary." % hdrs["Content-Type"])
				save_binary(uri, rb)

func save_binary(uri : URI, content):
	var file = File.new()
	file.open(uri.meta.save_path, File.WRITE)
	file.store_buffer(content)
	file.close()
	emit_signal("next_complete")
	
func save_text(uri : URI, content):
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
	const BINARY_OCTET_STREAM = "binary/octet-stream"
