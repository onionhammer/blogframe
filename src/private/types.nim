import times

# Types
type
    IView* = generic x
        render(x) is string
    BlogPost* = object
        content*, description*, title*, path*: string
        date*: TTime