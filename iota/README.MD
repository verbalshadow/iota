# Iota Client

Iota is a simple to use synchronous single source RPC client. For use with Godot Engine 3.x. It allows pooling of http queries for a single source.

# Sample project

Download or clone the git repository. Open the sample project in Godot Engine. Run the project. It will perform  a few web requests. You can view them 

# Usage

```
var http = IotaClient.new()
http.add_url("https://api.godsunchained.com/v0/match?page=1&perPage=20&start_time=1514764800-1611203726", HTTPClient.METHOD_GET, null, "user://match1.json")
# OR
var tempURI = URI.new()
tempURI.fill(sch, hst, prt, pth , qry, mthd, bdy, sv_pth)
http.add(tempURI)
