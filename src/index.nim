## Index of blog posts
import os, times, strutils, parseutils, algorithm
import private/types


# Types
type IndexReference = object
    file: string


# Procedures
template encode(value: string): string = value
template decode(value: string): string = value


proc format(p: BlogPost): string =
    ## Formats blog post metadata as a string row
    return $(p.date.int) & ";" &
        encode(p.path) & ";" &
        encode(p.title) & "\L"


proc open*(path: string): IndexReference =
    ## Open or create index file for blog posts
    return IndexReference(file: path)


proc reindex*(reference: IndexReference, posts: openarray[BlogPost] = []) =
    ## Delete & re-index all posts
    var gathered = newStringOfCap(1000)

    for item in posts:
        gathered.add(item.format)

    writeFile(reference.file, gathered)


iterator list*(reference: IndexReference): BlogPost =
    ## Yield back all blog posts in the index

    if existsFile(reference.file):

        for row in lines(reference.file):

            # Break on first empty line
            if row.len == 0: break

            # Parse file
            var s_date, path, title: string
            var i = 0

            inc i, row.parseUntil(s_date, ';') + 1
            inc i, row.parseUntil(path, ';', i) + 1
            title = row.substr(i)

            # Convert date
            var date = parseInt(s_date)

            yield BlogPost(
                title: decode(title),
                path: decode(path),
                date: TTime(date)
            )


proc add*(reference: IndexReference, post: BlogPost) =
    ## Add a blog post to the index

    # Insert record into index, in correct order
    var gathered = newStringOfCap(1000)
    var date     = post.date.int
    var added    = false

    for item in reference.list:
        if item.date.int > date:
            gathered.add(post.format)
            added = true
        gathered.add(item.format)

    if not added:
        gathered.add(post.format)

    # Save to file
    writeFile(reference.file, gathered)


when isMainModule:
    # Test index
    var reference = index.open("test.index")

    # Empty re-index should clear out index
    reference.reindex()

    # Add 1st item
    reference.add BlogPost(
        title: "some name; of a thing",
        path:  "filepath.rst",
        date:  getTime()
    )

    # Insert next item
    reference.add BlogPost(
        title: "This is something else",
        path:  "file2.rst",
        date:  (getTime().int - 10).TTime
    )

    # Test iteration
    var count = 0
    for i in reference.list:
        if   count == 0: assert i.title == "This is something else"
        elif count == 1: assert i.title == "some name; of a thing"
        inc count

    assert count == 2, "Number of items was incorrect"
