# Fields
var logFile         = ""
var logVerbosity    = 0


# Procedures
proc log*(information: string, verbosity = 3) =
    # TODO - Log to file


proc setLog*(log = "output.log", verbosity = 3) =
    logFile      = log
    logVerbosity = verbosity