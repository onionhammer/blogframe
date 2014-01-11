import times

get "/":
    header "Server", "WebFrame - Root Test"

    const style = css"""
        body {
           font-family: verdana;
           font-size: 15pt;
           background: #000;
           color: #FFF;
        }
        """

    tmpl html"""
        <style>$style</style>
        <script src=test.js></script>
        <title>Hello world!</title>
        <bold>Hello world!</bold>
        """

get "/test.js":
    header "Server", "WebFrame - Javascript"
    mime "application/javascript"

    const script = js"""
        var x = "hello world!";
        console.log(x);
        """

    result &= script

get "/handle":
    header "Server", "WebFrame - Writing directly to socket"
    sendHeaders
    response: tmpl html"""
        <title>Writing out response directly to socket!</title>
        <i>hello world!</i>
        """

get "/handle/complex/path": tmpl html"""
    <title>This is a more complex path!</title>
    <i>This is a more complex path!</i>
    """

get "/articles/@post": tmpl html"""
    Hello, you picked the $(@"post") page!<br>
    $if ?"page" != "" {
        page is: $(?"page")
    }
    """

cached "/test2/@post":
    header "Server", "WebFrame - Caching Test"
    tmpl html"""
        This page: "$(@"post")" was cached at
        $( getTime().getLocalTime().format("h:mm:ss tt") ).
        """

run(8080)