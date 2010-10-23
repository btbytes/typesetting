#!/bin/bash
curl http://bstring.cvs.sourceforge.net/viewvc/bstring/tree/bstrlib.txt\?pathrev\=HEAD -o bstrlib.txt
sed -i 's/===============================================================================//g' bstrlib.txt
pandoc bstrlib.txt -f markdown -t context --template=lesspaper-ltr.tex > bstrlib.tex
texexec bstrlib.tex

