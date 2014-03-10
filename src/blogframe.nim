# Imports
import os, strtabs
import packages/docutils/rstgen


# Types
type IView = generic x
    render(x) is string


# Procedures
template compile*(filename, content, pattern: string, body: stmt) {.immediate, dirty.} =

    # Find all files & iterate through them

    # For each file, retrieve content & call body

    # var content = readFile(path)



template action*(path, mime = "text/html", body: stmt) {.immediate.} =
    var result = ""


proc rst_to_html*(content: string): string =
    result = rstToHtml(
        content, {},
        newStringTable(modeStyleInsensitive)
    )


# Tests
when isMainModule:

    compile filename, content, "*.rst":
        var content = rstToHtml(content)


when false:

    import templates

    # Layout
    proc master(view: string): string = tmpli html"""
        <html>
            <div id="content">$view</div>
        </html>
        """

    # View (would be import)
    # import view
    type IndexInfo = object
        name: string

    # Render the model
    proc render(model: IndexInfo): string = tmpli html"""
        <h1>Hello there, $(model.name)</h1>
        """

    # get "/":
    var model = IndexInfo(name: "Smith")
    echo master(model.render)

    # Compile all articles to the public folder at start.
    # Also monitors pattern for changes and re-runs body if
    # changes occur.
    compile filename, rst, "/articles/*.rst":
        var content = rstToHtml(rst)
        writefile filename & ".html", master(content)

    action "/", "text/html": tmpl html"""
        <h1>Hello, world!</h1>
        """
