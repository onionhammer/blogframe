## Index of blog posts
import private/types

proc create*(name: string) =
    nil


proc add*(post: BlogPost) =
    nil


iterator list*: BlogPost =
    nil


when isMainModule:
    # Test index
    var post = BlogPost(title: "name")

    printPost(post)