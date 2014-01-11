# Reference:
# https://github.com/dom96/jester/blob/master/jester.nim

# TODO:
# - Cookies
# - Redirects
# - POST/Form data
# - GZIP
# - Responding w/ files
# - 'Compilation' of files
# - Filesystem change detection

# Imports
import macros, strtabs, tables
from cgi import decodeData
import server, templates, utility, logging
include responses

export strtabs, logging


# Types
type
    ResponseType* = enum
        Raw, Gzip, RawFile, GzipFile, Empty

    Transmission* = ref object of TObject
        cookies, headers: PStringTable
        client: TSocket

    HTTPRequest* = ref object of Transmission
        parameters, querystring: PStringTable
        fullPath: string

    HTTPResponse* = ref object of Transmission
        rawString: string
        status: string
        handled: bool

        case responseType: ResponseType
        of Raw, Gzip:
            value: string
        of RawFile, GzipFile:
            filename: string
        else: nil

    HTTPResponseCallback =
        proc(request: HTTPRequest, result: var HTTPResponse) {.nimcall.}

    Route = ref object
        pattern: string
        verb: string
        cache: bool
        parts: seq[string]
        variables: TTable[int, string]
        callback*: HTTPResponseCallback


# Fields
var routes          = newSeq[Route]()
var cachedResponses = initTable[string, HTTPResponse]()


# External Templates & Procedures
proc add*(result: var HTTPResponse, value: string) =
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


# Internal Procedures
proc parsePath(verb, path: string, cache: bool): Route =
    ## Parse the path and create a `TRoute`
    result = Route(
        verb:    verb,
        pattern: path,
        parts:   getParts(path),
        cache:   cache
    )

    result.variables = getVariables(result.parts)


proc isMatch(route: Route, verb: string, parts: seq[string], parameters: PStringTable): bool =
    ## Check if path matches input route
    return_ifnot route.verb == verb

    # Check route parts match input parts
    if parts.len == route.parts.len:
        for i in 0.. parts.len - 1:
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


proc makeRequest(route: Route, server: TServer, parameters: PStringTable): HTTPRequest =
    ## Encapsulate request
    result = HTTPRequest(
        fullPath:    server.path,
        parameters:  parameters,
        querystring: parseQueryString(server.query)
    )


template matchRoute(route, parameters: expr, body: stmt): stmt {.immediate.} =
    ## Find route matching request
    let verb  = server.reqMethod
    var parts = getParts(server.path)

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

        var response = HTTPResponse(
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

            if response.status == nil:
                response.status = CODE_200

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
            if route.cache and response.status == CODE_200:
                response.rawString = result
                cachedResponses[server.path] = response

            server.client.send result


template addRoute(verb, path: string, cache: bool, body: stmt): stmt {.immediate.} =
    bind HTTPRequest, parsePath, routes, add, cachedResponses
    var route = parsePath(verb, path, cache)

    route.callback = proc (request: HTTPRequest, result: var HTTPResponse) =
        when cache:
            var cachedResponse = webframe.cachedResponses[request.fullPath]

            # Check if result is cached
            if cachedResponse != nil:
                result.handled = true
                result.client &= cachedResponse.rawString

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


proc run*(port = 80) =
    ## Start web frame
    server.handleResponse = webframe.handleResponse
    server.start(port)


# Tests
when isMainModule:
    include tests