# Imports
import os, strtabs
import packages/docutils/rstgen


# Types
type IView* = generic x
    render(x) is string


# Procedures
template compile*(filename, content, pattern: string, body: stmt) {.immediate, dirty.} =
    bind walkFiles, readFile

    # TODO: Add filesystem monitor for this directory?

    # Find all files & iterate through them
    for filename in walkFiles(pattern):

        # For each file, retrieve content & call body
        var content = readFile(filename)

        # Call input body
        body


proc rst_to_html*(content: string): string =
    rstToHtml(
        content, {},
        newStringTable(modeStyleInsensitive)
    )


# Tests
when isMainModule:

    import templates

    proc master(view: string): string = tmpli html"""
        <html>
            <style>
                body { background: #000; color: #FFF; }
            </style>
            <div id="content">$view</div>
        </html>
        """

    compile filename, content, "*.rst":
        var html = rstToHtml(content)
        writefile filename.changeFileExt(".html"), master(html)