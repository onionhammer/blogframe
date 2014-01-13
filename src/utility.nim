# Imports
import parseutils


# Custom operators
template `??`*(value, default): expr =
    ## Retrieve the value or the default
    if value == nil: default
    else: value

template `@`*(p: string): expr =
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
