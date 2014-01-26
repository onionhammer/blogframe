import os
import templates, webframe, extensions.blog

# Publish static files
publish "/css/*.css"
publish "/scripts/*.js"
publish "/images/*.*"

# Compile blog articles
import extensions/views/article

compile articles:
    # Compile all articles at startup
    for f in walk_files(root/ "articles/*.txt"):
        save(f, ".html", article(readFile(f)))

get "/article/@page":
    # Serve cached article
    result.add articles(@"page")

get "/": tmpl html"""
    <div>hello world!</div>
    """

get "/notfound": tmpl html"""
    <div>Sorry, don't know what you're looking for</div>
    """

webframe.run(8080)