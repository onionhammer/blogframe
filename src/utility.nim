import strtabs, parseutils, strutils, tables
from cgi import urlDecode


template header*(key, value): expr =
    result.headers[key] = value


template mime*(value): expr =
    header "Content-Type", value


template status*(value): expr =
    result.status = value


template `??`*(value, default): expr =
    ## Retrieve the value or the default
    if value == nil: default
    else: value


template `@`*(p): expr {.immediate.} =
    ## Retrieve the parameter from the string
    request.parameters[$p]


template `?`*(p): expr {.immediate.} =
    ## Retrieve querystring value
    request.querystring[$p] ?? ""


template return_ifnot*(cond): expr =
    if not cond:
        return false


proc getParts*(path: string): seq[string] =
    ## Break up the path by `/`
    result = newSeq[string]()

    var i = 1
    while i < path.len:
        var value: string
        inc(i, path.parseUntil(value, '/', i) + 1)
        result.add value


proc getVariables*(parts: seq[string]): TTable[int, string] =
    ## Retrieve the variable portions of the path
    result = initTable[int, string](16)

    for i in 0.. parts.len - 1:
        var p = parts[i]

        if p[0] == '@':
            result[i] = p.substr(1)


proc parseQueryString*(query: string): PStringTable =
    ## Parse out querystring in path
    result = newStringTable()

    var key: string
    var i = 0

    while i < query.len:
        var value: string
        inc(i, query.parseUntil(value, {'&', '='}, i))
        if query[i] == '=':
            key = urlDecode(value)
        elif key != nil:
            result[key] = urlDecode(value)
            key = nil
        inc(i)


proc parseParams*(path: seq[string], parts: TTable[int, string]): PStringTable =
    ## Determines if input path matches up with
    var
        init      = true
        partIndex = 0

    for value in path:

        if parts.hasKey(partIndex):
            if init:
                result = newStringTable()
                init   = false

            result[parts[partIndex]] = value

        inc partIndex
