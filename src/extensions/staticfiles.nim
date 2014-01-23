proc publish*(path: string) =
    ## Processs & publish the input path (pattern)
    nil

template compile*(ident: expr, body: stmt): stmt {.immediate, dirty.} =
    ## Compile the body into the input identifier
    nil