# Publish static files
publish "/css/*.css"
publish "/scripts/*.js"
publish "/images/*.*"

# Compile blog articles
import views/article

compile articles:
    # Compile all articles at startup
    for f in files(root/ "articles/*.rst"):
        save(f, article(readFile(f)))

# cached "/":
#    # Serve default article

cached "/article/@page":
    # Serve cached article
    # articles(@"page")