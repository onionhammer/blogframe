## Index of blog posts
import os, times, strutils, parseutils
import private/types


# Types
type IndexReference = object
    file: string


# Procedures
template encode(value: string): string = value
template decode(value: string): string = value


proc open*(path: string): IndexReference =
    ## Open or create index file for blog posts
    return IndexReference(file: path)


iterator list*(reference: IndexReference): BlogPost =

    if existsFile(reference.file):

        ## Yield back all blog posts in the index
        for row in lines(reference.file):

            # Parse file
            var s_date, path, title: string
            var i = 0

            inc i, row.parseUntil(s_date, ';') + 1
            inc i, row.parseUntil(path, ';', i) + 1
            title = row.substr(i)

            # Convert date
            var date = parseInt(s_date)

            yield BlogPost() #, path: decode(path), date: TTime(date))


proc add*(reference: IndexReference, post: BlogPost) =
    ## Add a blog post to the index

    proc format(p: BlogPost): string =
        return $(p.date.int) & ";" &
            encode(post.path) & ";" &
            encode(post.title)

    # Insert record into index, in correct order
    var gathered = newStringOfCap(1000)
    var date     = post.date.int

    for item in reference.list:
        if item.date.int > date:
            gathered.add(post.format)

        gathered.add(item.format)

    if gathered.len == 0:
        gathered.add(post.format)

    # Save to file
    writeFile(reference.file, gathered)


when isMainModule:
    # Test index
    var reference = index.open("somefile.index")

    var post = BlogPost(
        title: "some name; of a thing",
        path: "filepath.rst",
        date: getTime()
    )

    reference.add(post)

