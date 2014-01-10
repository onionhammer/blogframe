import webframe, templates


cached "/":
    # Do nothing
    echo "hello cached page!"


get "/page":
    # Do nothing!
    echo "hello page!"

run()