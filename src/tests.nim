# Imports
import times


# Paths
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
        <script src=test.js async></script>
        <style>$style</style>
        <title>Hello world!</title>
        <bold>Hello world!</bold>
        """

get "/test.js":
    header  "Server", "WebFrame - Javascript"
    mime    "application/javascript"
    maxage   600
    sendfile "test.js", true

get "/handle":
    header "Server", "WebFrame - Writing directly to socket"
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

get "/cookies":
    var expiration = getTime().getGMTime() + initInterval(days=1)
    cookie("testcookie", "hello world!", expiration)
    tmpl html"""
        Your cookie says: $(cookie("testcookie"))
        """

cached "/test2/@post":
    header "Server", "WebFrame - Caching Test"
    maxage 600
    tmpl html"""
        This page: "$(@"post")" was cached at
        $( getTime().getLocalTime.format("h:mm:ss tt") ).
        """

get "/redirect":
    header "Server", "WebFrame - Test Redirects"
    if ?"redirected" == "":
        redirect "/redirect?redirected=1"
    else:
        result &= "Redirect successful!"

get "/form":
    header "Server", "WebFrame - Test Forms"
    tmpl html"""
        <form method=POST>
            <p>hello, please fill this in:
            <p>my name is <input name="name">
            <p>and i'm <input name="age"> years old
            <p><button>go!</button>
        </form>
        """

post "/form":
    header "Server", "WebFrame - Test Forms"
    if form("name") != "":
        tmpl html"""
            Hello $(form("name")),
            I see you're $(form("age"))
            """
    else:
        result &= "Sorry, didn't get that"

get "/upload":
    header "Server", "WebFrame - Test Forms"
    tmpl html"""
        <form method=POST enctype="multipart/form-data">
            <p>file: <input name=file type=file>
            <p>save as: <input name=filename>
            <p><button>Upload</button>
        </form>
        """

post "/upload":
    header "Server", "WebFrame - Test Forms"
    var file     = files("file")
    var filename = file.fields["filename"]

    if filename != nil and file.body != nil:
        tmpl html"""
            <p>Filename: $filename
            <p>New Name: $(form("filename"))
            <p>Content:
            <pre>$(file.body)</pre>
            """
    else:
        result &= "Didn't understand your request"


get "/deflate":
    result.responseType = Deflate
    header "Server", "WebFrame - Dynamic Deflate Test!"
    tmpl html"""
        <p>Hello, this is some stuff!</p>
        <ul>
            $for i in 1.. 100 {
                <li>$i</li>
            }
        </ul>
        """

run(8080)