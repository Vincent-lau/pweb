#!/usr/bin/zsh

pdflatex -shell-escape image.tex && \
pdftoppm image.pdf image -png -singlefile -rx 800 -ry 800 && \
mv image.png $1/$2.png

