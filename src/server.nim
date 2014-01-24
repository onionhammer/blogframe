# Imports
import macros
import nimuv
export nimuv

# Fields
var handleResponse*: proc(server: TUVRequest)

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
template protocol*(code = CODE_200): expr =
    result &= "HTTP/1.1 " & code & wwwnl


template line*(value: string = ""): expr =
    result &= value & wwwnl


template sendResponse*(server, result: expr, body: stmt): stmt {.immediate.} =
    var result = ""
    body
    server.add(result)


proc defaultResponse(server: TUVRequest) =
    sendResponse(server, result):
        protocol CODE_501
        line "Content-type: text/html"
        line
        line "Server not set up"


proc handleHttpRequest*(server: TUVRequest) =
    when defined(debug):
        handleResponse(server)

    else:
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

    server.close()


proc start*(port = 8080, reuseAddr = true) =
    nimuv.handleResponse = server.handleHttpRequest
    nimuv.run(port = port)


# Initialize
handleResponse = defaultResponse