import templates

proc article*(content: string): string = tmpli html"""
    <title>Article</title>
    <div id=content>
        $content
    </div>
    """