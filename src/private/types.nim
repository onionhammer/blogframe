import times

# Types
type
    IView* = generic x
        render(x) is string
    BlogPost* = ref object
        content*, description*, title*, cached*: string
        date*: TTime