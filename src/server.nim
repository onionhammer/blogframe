# Imports
import macros
import httpserver, sockets
export httpserver, sockets

# Fields
var server*: TServer
var handleResponse*: proc(server: TServer)

const
    CODE_200* = "200 OK"
    CODE_301* = "301 Moved Permanently"
    CODE_302* = "302 Found"
    CODE_303* = "303 See Other"
    CODE_400* = "400 Bad Request"
    CODE_401* = "401 Unauthorized"
    CODE_403* = "403 Forbidden"
    CODE_404* = "404 Not Found"
    CODE_500* = "500 Internal Server Error"
    CODE_501* = "501 Not Implemented"


# Procedures
template `&=`*(result, value): expr {.immediate.} =
    add(result, value)


proc add*(result: TSocket, value: string) =
    result.send(value)


template protocol*(code = CODE_200): expr =
    result &= "HTTP/1.1 " & code & wwwnl


template line*(value: string = ""): expr =
    result &= value & wwwnl


template sendResponse*(server, result: expr, body: stmt): stmt {.immediate.} =
    var result = ""
    body
    server.client.send(result)


proc defaultResponse(server: TServer) =
    sendResponse(server, result):
        protocol CODE_501
        line "Content-type: text/html"
        line
        line "Server not set up"


proc handleHttpRequest*(server: TServer) =
    var client = server.client

    try:
        # Generate a response
        handleResponse(server)

    except:
        # Display error page
        sendResponse(server, result):
            protocol CODE_400
            line "Content-type: text/html"
            line
            line "Could not handle request"

    client.close()


proc start*(port = 8080, reuseAddr = true) =
    server.open(port.TPort, reuseAddr)

    while true:
        server.next()
        server.handleHttpRequest()


# Initialize
handleResponse = defaultResponse