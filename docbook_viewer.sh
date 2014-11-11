#!/bin/bash

#
# The first version of very simple (and probably buggy :)
# autorenderer for DocBook section that is changed/edited."
# Pavel Tisnovsky, Red Hat
# Jaromir Hradilek, Red Hat (xsltproc part)
#
# Packages required to use this tool:
# - midori
# - yelp-xsl
# - libxslt
# - inotify-tools
# - (and Bash, of course)
#



# Creates the first HTML page that will be shown in the Midori browser
# when this script is started
function createFirstHtmlPage() {
    echo "<html><head><title>DocBook Preview</title></head><body>DocBook Preview</body></html>" > out.html
}



# Starts Midori browser and opens the file out.html.
function startMidori() {
    midori out.html &
}



# Converts selected XML file into HTML (out.html)
function printToHtml() {
# Author: Jaromir Hradilek
  local -r file="$1"

  # Convert the file to HTML:
  cat <<-'EOF' | xsltproc - "$file"
<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                version="1.0">
  <xsl:import href="/usr/share/yelp-xsl/xslt/docbook/html/db2html.xsl"/>
  <xsl:param name="db.chunk.max_depth" select="0"/>
  <xsl:template name="html.output">
    <xsl:param name="node" select="."/>
    <xsl:call-template name="html.page">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
    <xsl:apply-templates mode="html.output.after.mode" select="$node"/>
  </xsl:template>
  <xsl:template name="html.page">
    <xsl:param name="node" select="."/>
    <html>
      <head>
        <link type="text/css" rel="stylesheet" href="/docbook.css"/>
        <title>
          <xsl:apply-templates mode="html.title.mode" select="$node"/>
        </title>
      </head>
      <body>
        <div class="page" role="main">
          <div class="body">
            <xsl:apply-templates mode="html.body.mode" select="$node"/>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
EOF
}



# Converts selected XML file into HTML (out.html) and reload this HTML in Midori.
function buildAndShowChangedSection() {
    echo "$filename"
    printToHtml $filename > out.html 2> /dev/null
    #./build-chunk.sh $filename > out.html 2> /dev/null
    echo "Reloading new content into the web browser"
    midori -e Reload
}



# In this function the script wait for any change in any
# XML file stored in the en-US subdirectory
function mainLoop() {
    echo "Entering main loop"
    while true
    do
        filename=`inotifywait -r -e modify,create --format "%w%f" en-US/ 2> /dev/null`
        basename=$(basename "$filename")
        extension="${basename##*.}"
        if [[ _${extension} == "_xml" ]]
        then
            buildAndShowChangedSection $filename
        fi
    done
}



# Startup sequence
function run() {
    createFirstHtmlPage
    startMidori
    mainLoop
}

run

