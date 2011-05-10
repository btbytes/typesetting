#!/bin/bash
echo "URL : $@"
fname=`basename $1`
curl -s $1 -O
echo "Source: $fname"
filename=$(basename $fname)
extension=${filename##*.}
filename=${filename%.*}
case "$extension" in
	md|mkd|txt)
	    format="markdown"
	    ;;
	rst)
	    format="rst"
            ;;	
	textile)
	    format="textile"
            ;;

	html)
	    format="html"
	    ;;
 	*)
	    format="markdown"
            
esac

pandoc $fname -f $format -t context --template=/home/pradeep/src/typesetting/markdown2pdf/lesspaper-ltr.tex > ${filename}.tex
texexec --pdf --silent --purgeall ${filename}.tex >> /dev/null
echo "Output: ${filename}.pdf"
