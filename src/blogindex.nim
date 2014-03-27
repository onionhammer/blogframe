## Index of blog posts
import times, tables
import private/types
from blogframe import titleEncode


# Types
type IndexReference* = ref object
    table: TOrderedTable[string, BlogPost]


# Procedures
proc open*: IndexReference =
    ## Open or create index for blog posts
    IndexReference(table: initOrderedTable[string, BlogPost]())


iterator list*(reference: IndexReference): BlogPost =
    for post in reference.table.values:
        yield post


proc add*(reference: IndexReference, post: BlogPost) =
    ## Add a blog post to the index
    reference.table.add (titleEncode(post.title), post)


proc build*(reference: var IndexReference) =
    ## Build a new ordered index from the inserted pairs
    type TPair = tuple[key: string, val: BlogPost]

    sort(
        reference.table,
        proc (a, b: TPair): int = cmp(b.val.date.int, a.val.date.int)
    )


proc `[]`*(reference: IndexReference, title: string): BlogPost {.noinit.} =
    ## Find matching title
    reference.table[title]


when isMainModule:
    # Test index
    var reference = blogindex.open()

    # Add 1st item
    reference.add BlogPost(
        title: "some name; of a thing",
        date:  getTime()
    )

    # Insert next item
    reference.add BlogPost(
        title: "This is something else",
        date:  (getTime().int - 100).TTime
    )

    # Build index
    reference.build()

    # Test iteration
    var count = 0
    for i in reference.list:
        if   count == 1: assert i.title == "This is something else"
        elif count == 0: assert i.title == "some name; of a thing"
        inc count

    assert count == 2, "Number of items was incorrect"

    # Test lookup
    assert reference["This-is-something-else"].title == "This is something else"