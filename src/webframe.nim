# Reference:
# https://github.com/dom96/jester/blob/master/jester.nim

# Imports
import macros, strtabs
import server, templates, utility

export strtabs

include responses


# Types
type
    TResponseType* = enum
        Raw, Gzip, RawFile, GzipFile, Empty

    TTransmission* = ref object of TObject
        cookies, headers: PStringTable
        client: TSocket

    TRequest* = object of TTransmission

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
        callback*: TResponseCallback


# Fields
var logFile      = ""
var logVerbosity = 0
var routes       = newSeq[TRoute]()
# var cache = {:}.newStringTable()


# Procedures
proc log*(information: string, verbosity = 3) =
    # TODO - Log to file


proc parsePath(verb, path: string, cache: bool): TRoute =
    # TODO - Parse the path
    return TRoute(verb: verb, pattern: path)


proc isMatch(route: TRoute, verb, path, query: string): bool =
    #TODO - Do more sophisticated pattern matching
    return route.verb == verb and
           route.pattern == path


proc add*(result: var TResponse, value: string) =
    result.value &= value


template matchRoute(route: expr, body: stmt): stmt {.immediate.} =
    let
        verb  = server.reqMethod
        path  = server.path
        query = server.query

    # Attempt to find a matching route
    for route in routes:
        if route.isMatch(verb, path, query):
            body
            return

    server.not_found()


template sendHeaders(response: expr, now=true) =
    ## Immediately send headers
    protocol response.status ?? CODE_200

    if not response.headers.hasKey("Content-Type"):
        line "Content-Type: text/html"

    for key,value in response.headers:
        line key & ": " & value

    line

    when now:
        response.client.send(response.value)


template frame(body: stmt) {.immediate, dirty.} =
    block:
        result.handled = true
        var result = result.client
        body


proc handleResponse(server: TServer) =
    ## Handles all requests sent in from server

    # Determine path & verb
    matchRoute(route):
        # Create request & response objects
        # and pass them to the route's callback
        var request  = TRequest()
        var response = TResponse(
            responseType: Raw,
            value: "",
            client: server.client,
            headers: newStringTable()
        )

        route.callback(request, response)

        # This is the default way of handling a response
        # when the callback essentially constructs a string
        # which the server sends back.
        if not response.handled:

            var result = ""

            sendHeaders(response, false)

            case response.responseType
            of Raw:
                result &= response.value

            of Gzip:
                #TODO- Set response encoding
                result &= response.value

            of RawFile:
                #TODO - Read file

            of GzipFile:
                #TODO - Set response encoding AND read file

            else:
                nil # Send no response

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

        template style = tmpl css"""
            body {
               font-family: verdana;
               font-size: 15pt;
               background: #000;
               color: #FFF;
            }
            """

        tmpl html"""
            <style>${ style }</style>
            <script src=test.js></script>
            <title>Hello world!</title>
            <bold>Hello world!</bold>
            """

    get "/test.js":
        header "Server", "WebFrame - Javascript"
        mime "application/javascript"

        tmpl js"""
            var x = "hello world!";
            console.log(x);
            """

    get "/handle":
        header "Server", "WebFrame - Handling Test"
        sendHeaders(result)
        frame:
            tmpl html"""
                <i>hello world!</i>
                """

    run(8080)