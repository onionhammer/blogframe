# Imports
import times, strtabs, parseutils, strutils, tables, cookies
from cgi import urlDecode


# Header Procedures
template header*(key, value): expr =
    result.headers[key] = value

template mime*(value): expr =
    header "Content-Type", value

template date*(time): expr =
    ## Format time & injects in header
    header "Date", headerDate(time)

template expires*(time): expr =
    ## Format time & injects in header
    header "Expires", headerDate(time)

template maxAge*(seconds): expr =
    ## Inject max-age into header
    header "Cache-Control", "max-age=" & $seconds

template status*(value): expr =
    result.status = value

template cookie*(key): expr =
    ## Retrieve a cookies
    request.cookies[key] ?? ""

template cookie*(key, value: string; expires: TTimeInfo;
                 domain = ""; path = ""): expr =
    ## Set a cookie
    bind setCookie
    result.cookies[key] = setCookie(key, value, expires, domain, path, true)

template redirect*(path: string, permenant = false) =
    ## Redirect to input path
    when permenant: status CODE_301
    else:           status CODE_302
    header "Location", path


# Custom operators
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

template form*(p): expr {.immediate.} =
    ## Retrieve form value
    request.form[p] ?? ""

template files*(p): expr {.immediate.} =
    ## Retrieve a file value
    request.files[p]

# Helper Procedures
proc headerDate*(time: TTimeInfo): string =
    time.format("ddd, dd MMM yyyy HH:mm:ss") & " GMT"

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


proc parseKeyValue(key, value: var string, line: string) =
    ## Parse out header key: value pair
    var i = 0
    inc(i, line.parseUntil(key, ':', i) + 1)
    inc(i, line.skipWhiteSpace(i))
    discard line.parseUntil(value, {'\r', '\L'}, i)

proc parseContentDisposition(header): tuple[name, filename: string] =
    ## Parse out multi-part form data content disposition
    var i = 0
    while i < header.len:
        var pair, key, value: string
        inc(i, header.parseUntil(pair, {';', ' '}, i) + 1)
        var j = pair.parseUntil(key, '=')
        if j > 0:
            let lkey = key.toLower
            if lkey == "name":
                result.name = pair.captureBetween('"', start=j)
            elif lkey == "filename":
                result.filename = pair.captureBetween('"', start=j)

template parsePart(part: string) {.immediate.} =
    # Parse out content disposition, if it's a file put it into files,
    # otherwise put it into form.
    # Iterate through lines
    var j = 0
    var isFile = false
    var partName: string
    var filePart: tuple[fields: PStringTable, body: string]

    while j < part.len:
        var key, value, line: string
        inc(j, part.parseUntil(line, '\L', j) + 1)
        if line == "\r": break
        parseKeyValue(key, value, line)

        if key.toLower == "content-disposition":
            let disposition = parseContentDisposition(value)
            partName = disposition.name ?? ""
            isFile   = disposition.filename != nil
            if isFile:
                filePart.fields = newStringTable()
                filePart.fields["filename"] = disposition.filename

        elif isFile:
            filePart.fields[key] = value

    if isFile:
        filePart.body   = part.substr(j)
        files[partName] = filePart
    else:
        form[partName] = part.substr(j)

proc parseMultipartForm*(contentType, body: string,
        form: var PStringTable,
        files: var TTable[string, tuple[fields: PStringTable, body: string]]) =
    ## Parse the multi-part form data
    # Parse content type
    var boundaryIndex = contentType.find("boundary=")
    if boundaryIndex < 0: return
    let boundary = "--" &contentType.substr(boundaryIndex + 9)
    const nlLen = "\r\L".len

    # Initialize files table
    files = initTable[string, tuple[fields: PStringTable, body: string]]()
    form  = newStringTable()

    # Parse body
    var i = 0
    while i < body.len:
        # Assume we're at the beginning of a boundary
        # Find the next boundary marker
        var nextIndex = body.find(boundary, i)

        if nextIndex > i:
            # Get & parse part
            var part = body.substr(i, nextIndex - 1 - nlLen)
            parsePart(part)
            i = nextIndex

        # Seek to end of boundary
        inc(i, body.skip(boundary, i) + nlLen)

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
    ## Determines if input path matches up with parts
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