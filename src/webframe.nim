# Reference:
# https://github.com/dom96/jester/blob/master/jester.nim

# TODO:
# - Responding w/ files
# - Cleanup utility
# - GZIP, zopfli
# - 'Compilation' of files
# - Filesystem change detection

# Imports
import macros, strtabs, strutils, tables, cookies
import server, templates, utility, logging, headerOps
include responses

export strtabs, logging, headerOps


# Types
type
    HTTPResponseCallback =
        proc(request: HTTPRequest, result: var HTTPResponse) {.nimcall.}

    FileData* =
        TTable[string, tuple[fields: PStringTable, body: string]]

    ResponseType* = enum
        Raw, Gzip, RawFile, GzipFile, Empty

    Transmission* = object of TObject
        cookies, headers: PStringTable
        client: TSocket

    HTTPRequest* = ref object of Transmission
        parameters, querystring, form: PStringTable
        files: FileData
        fullPath: string

    HTTPResponse* = ref object of Transmission
        rawString, status: string
        handled: bool
        case responseType: ResponseType
        of Raw, Gzip:
            value: string
        of RawFile, GzipFile:
            filename: string
        else: nil

    Route = object
        pattern: string
        verb: string
        cache: bool
        parts: seq[string]
        variables: TTable[int, string]
        callback: HTTPResponseCallback


# Fields
var routes          = newSeq[Route]()
var cachedResponses = initTable[string, HTTPResponse]()


# Internal Procedures
proc parsePath(verb, path: string, cache: bool): Route =
    ## Parse the path and create a `Route`
    var parts = getParts(path)

    return Route(
        verb:      verb,
        pattern:   path,
        parts:     parts,
        variables: getVariables(parts),
        cache:     cache
    )


proc isMatch(route: Route, verb: string, parts: seq[string], parameters: PStringTable): bool =
    ## Check if path matches input route
    return_ifnot route.verb == verb

    # Check route parts match input parts
    return_ifnot parts.len == route.parts.len

    # Check variables
    for i in 0.. parts.len - 1:
        if not route.variables.hasKey(i):
            return_ifnot parts[i] == route.parts[i]

    # Check route length
    if route.variables.len > 0:
        return_ifnot parameters != nil
        return route.variables.len == parameters.len

    return true


proc makeRequest(route: Route, server: TServer, parameters: PStringTable): HTTPRequest =
    ## Encapsulate request
    var cookies =
        if server.headers["Cookie"] != nil: parseCookies(server.headers["Cookie"])
        else: newStringTable()

    result = HTTPRequest(
        fullPath:    server.path,
        parameters:  parameters,
        querystring: parseQueryString(server.query),
        cookies:     cookies
    )

    if route.verb == "POST":
        var contentType = server.headers["Content-Type"] ?? ""
        if contentType == "application/x-www-form-urlencoded":
            result.form = parseQueryString(server.body)
        elif contentType.startsWith("multipart/form-data"):
            parseMultipartForm(contentType, server.body, result.form, result.files)


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
            headers:      newStringTable(),
            cookies:      newStringTable()
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
                # Set response encoding
                line "Content-Encoding: gzip"
                line # Write another line to indicate end of headers
                # TODO - GZip value
                result &= response.value

            of RawFile:
                # TODO - Read file

            of GzipFile:
                # TODO - Set response encoding AND read file
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
    bind HTTPRequest, HTTPResponse
    bind parsePath, routes, add, cachedResponses

    var route = parsePath(verb, path, cache)

    route.callback = proc (request: HTTPRequest, result: var HTTPResponse) =
        when cache:
            var cachedResponse = cachedResponses[request.fullPath]

            # Check if result is cached
            if cachedResponse != nil:
                result.handled = true
                result.client &= cachedResponse.rawString
                return

        body

    routes.add(route)


# External Webframe Interface
template get*(path: string, body: stmt): stmt {.immediate.} =
    ## Add a GET path handler
    bind addRoute
    addRoute("GET", path, false, body)


template cached*(path: string, body: stmt): stmt {.immediate.} =
    ## Add a cached GET path handler
    bind addRoute
    addRoute("GET", path, true, body)


template post*(path: string, body: stmt): stmt {.immediate.} =
    ## Add a POST path handler
    bind addRoute
    addRoute("POST", path, false, body)


proc add*(result: var HTTPResponse, value: string) =
    ## Append value to response
    result.value &= value


proc run*(port = 80) =
    ## Start web frame
    server.handleResponse = webframe.handleResponse
    server.start(port)


# Tests
when isMainModule:
    include tests