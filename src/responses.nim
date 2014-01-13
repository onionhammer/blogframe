# Default Style
template style = tmpl css"""
    body {
        font-family: verdana;
    }
    p {
        font-size: 18pt;
    }
    """

# Canned responses
proc not_found(server: TServer) =
    sendResponse(server, result):
        protocol CODE_404
        line

        when defined(custom_404):
            result &= custom_404

        else:
            tmpl html"""
                <style>${ style }</style>
                <p>404 Not Found</p>
                """