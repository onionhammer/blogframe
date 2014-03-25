import times

# Types
type
    IView* = generic x
        render(x) is string
    BlogPost* = ref object
        content*, description*, title*: string
        date*: TTime