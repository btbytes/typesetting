#!/bin/bash
curl -s http://bstring.cvs.sourceforge.net/viewvc/bstring/tree/bstrlib.txt\?pathrev\=HEAD -o bstringlib.txt 
sed -i 's/===============================================================================//g' bstringlib.txt
pandoc  bstringlib.txt -f markdown -t context --template=lesspaper-ltr.tex > bstringlib.tex 
texexec --pdf --silent --purgeall bstringlib.tex 
