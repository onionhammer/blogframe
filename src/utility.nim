
template header*(key, value): expr =
    result.headers[key] = value

template mime*(value): expr =
    header "Content-Type", value

template status*(value): expr =
    result.status = value

template `??`*(value, default): expr =
    if value == nil: default
    else: value
