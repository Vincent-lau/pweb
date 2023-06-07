#!/usr/bin/env sh

pdflatex -shell-escape -interaction=nonstopmode -file-line-error -output-directory=$1 image.tex
