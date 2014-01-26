# Imports
import os


# Procedures
proc getRoot*: string = "." #TODO - Setting


proc getCompiled*: string = getRoot() / "compiled"


template root*: expr =
    bind getRoot
    getRoot()


proc save*(file, newExtension, content: string) =
    ## Save file content
    var (dir, filename, ext) = splitFile(file)

    # TODO - Find 'Compiled location'
    # var destDir = getCompiled()
    var destDir = dir

    writefile(destDir / (filename & newExtension), content)


proc publish*(path: string) =
    ## Process & publish the input path (pattern)


template compile*(ident: expr, body: stmt): stmt {.immediate, dirty.} =
    ## Compile the body into the input identifier
    body

    # Create a template named after the input `ident`
    proc ident(key: string): string =
        return "smelllooo: " & key