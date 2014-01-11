# Reference:
# https://github.com/dom96/jester/blob/master/jester.nim

# Imports
import macros, strtabs, tables
from cgi import decodeData
import server, templates, utility
include responses

export strtabs


# Types
type
    TResponseType* = enum
        Raw, Gzip, RawFile, GzipFile, Empty

    TTransmission* = ref object of TObject
        cookies, headers: PStringTable
        client: TSocket

    TRequest* = object of TTransmission
        parameters, querystring: PStringTable

    TResponse* = object of TTransmission
        rawString: string
        status: string
        handled: bool

        case responseType: TResponseType
        of Raw, Gzip:
            value: string
        of RawFile, GzipFile:
            filename: string
        else: nil

    TResponseCallback = proc(request: TRequest, result: var TResponse) {.nimcall.}

    TRoute = ref object
        pattern: string
        verb: string
        cache: bool
        parts: seq[string]
        variables: TTable[int, string]
        callback*: TResponseCallback


# Fields
var logFile      = ""
var logVerbosity = 0
var routes       = newSeq[TRoute]()
# var cache = {:}


# External Templates & Procedures
proc log*(information: string, verbosity = 3) =
    # TODO - Log to file


proc add*(result: var TResponse, value: string) =
    result.value &= value


template sendHeaders*(now = true) =
    ## Send headers
    sendHeaders(result, now)


template sendHeaders*(response: expr, now = true) =
    ## Send headers
    protocol response.status ?? CODE_200

    if not response.headers.hasKey("Content-Type"):
        line "Content-Type: text/html"

    for key,value in response.headers:
        line key & ": " & value

    when now:
        line
        response.client.send(response.value)


template response*(body: stmt) {.immediate, dirty.} =
    block:
        result.handled = true
        var result = result.client
        body


template `@`(p): expr {.immediate.} =
    ## Retrieve the parameter from the string
    request.parameters[$p]


template `?`(p): expr {.immediate.} =
    request.querystring[$p] ?? ""


# Internal Procedures
proc parsePath(verb, path: string, cache: bool): TRoute =
    # TODO - Parse the path
    result = TRoute(
        verb:    verb,
        pattern: path,
        parts:   getParts(path)
    )

    result.variables = getVariables(result.parts)


proc isMatch(route: TRoute, verb: string, parts: seq[string], parameters: PStringTable): bool =
    ## Check if path matches input route
    return_ifnot route.verb == verb

    # Check route parts match input parts
    if parts.len == route.parts.len:
        for i in 0 .. parts.len - 1:
            if not route.variables.hasKey(i):
                return_ifnot parts[i] == route.parts[i]
    else:
        return false

    if route.variables.len > 0:
        if parameters != nil:
            result = result and route.variables.len == parameters.len
        else:
            return false

    return true


proc makeRequest(route: TRoute, server: TServer, parameters: PStringTable): TRequest =
    # Parse params & querystring
    result = TRequest(
        parameters:  parameters,
        querystring: parseQueryString(server.query)
    )


template matchRoute(route, parameters: expr, body: stmt): stmt {.immediate.} =
    ## Find route matching request
    let
        verb  = server.reqMethod
        path  = server.path
        query = server.query

    var parts = getParts(path)

    # Attempt to find a matching route
    for route in routes:
        var parameters = parseParams(parts, route.variables)

        if route.isMatch(verb, parts, parameters):
            body
            return

    server.not_found()


proc handleResponse(server: TServer) =
    ## Handles all requests sent in from server

    # Determine path & verb
    matchRoute(route, parameters):
        # Create request & response objects
        # and pass them to the route's callback
        var request = route.makeRequest(server, parameters)

        var response = TResponse(
            responseType: Raw,
            value:        "",
            client:       server.client,
            headers:      newStringTable()
        )

        route.callback(request, response)

        # This is the default way of handling a response
        # when the callback essentially constructs a string
        # which the server sends back.
        if not response.handled:

            var result = "" # TODO - Use a buffered response object?
            sendHeaders(response, false)

            case response.responseType
            of Raw:
                line # Write another line to indicate end of headers
                result &= response.value

            of Gzip:
                #TODO - Set response encoding
                line "Content-Encoding: gzip"
                line # Write another line to indicate end of headers
                result &= response.value

            of RawFile:
                #TODO - Read file

            of GzipFile:
                #TODO - Set response encoding AND read file
                line "Content-Encoding: gzip"
                line # Write another line to indicate end of headers

            of Empty:
                return # Send no response

            # Cache the response if the route calls for it
            if route.cache:
                response.rawString = result
                #TODO cache.insert(route, response)

            server.client.send result


template addRoute(verb, path: string, cache: bool, body: stmt): stmt {.immediate.} =
    bind parsePath, routes, TRequest, add

    block:
        var route = parsePath(verb, path, cache)

        route.callback = proc (request: TRequest, result: var TResponse) {.nimcall.} =
            when cache:
                block: #TODO - Check if result is cached
                    result.handled = true
                    echo "cached!!"
            body

        routes.add(route)


template get*(path: string, body: stmt): stmt {.immediate.} =
    bind addRoute
    addRoute("GET", path, false, body)


template post*(path: string, body: stmt): stmt {.immediate.} =
    bind addRoute
    addRoute("POST", path, false, body)


template cached*(path: string, body: stmt): stmt {.dirty, immediate.} =
    bind addRoute
    addRoute("GET", path, true, body)


proc setLog*(log = "output.log", verbosity = 3) =
    logFile      = log
    logVerbosity = verbosity


proc run*(port = 80) =
    ## Start web frame
    server.handleResponse = webframe.handleResponse
    server.start(port)


# Tests
when isMainModule:

    get "/":
        header "Server", "WebFrame - Root Test"

        const style = css"""
            body {
               font-family: verdana;
               font-size: 15pt;
               background: #000;
               color: #FFF;
            }
            """

        tmpl html"""
            <style>$style</style>
            <script src=test.js></script>
            <title>Hello world!</title>
            <bold>Hello world!</bold>
            """

    get "/test.js":
        header "Server", "WebFrame - Javascript"
        mime "application/javascript"

        const script = js"""
            var x = "hello world!";
            console.log(x);
            """

        result &= script

    get "/handle":
        header "Server", "WebFrame - Handling Test"
        sendHeaders
        response:
            tmpl html"""
                <title>Writing out response directly to socket!</title>
                <i>hello world!</i>
                """

    get "/handle/complex/path":
        tmpl html"""
            <title>This is a more complex path!</title>
            <i>This is a more complex path!</i>
            """

    get "/articles/@post": tmpl html"""
        Hello, you picked the $(@"post") page!<br>
        $if ?"page" != "" {
            page is: $(?"page")
        }
        """

    run(8080)