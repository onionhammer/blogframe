# Imports
import zlib

# Procedures & templates
proc deflateString*(source: string): string =

    var sourcelen = source.len
    var destLen   = sourcelen + (sourcelen.float * 0.1).int + 16
    result        = newString(destLen)

    # DEFLATE result
    if zlib.compress(addr result[0], addr destLen, source.cstring, sourceLen) != Z_OK:
        raise newException(EIO, "Failed to compress")

    # Resize DEFLATE response
    result.setLen(destLen)