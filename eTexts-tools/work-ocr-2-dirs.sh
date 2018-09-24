#! /bin/bash

base="/Users/chris/Desktop/TBRC/eTexts-Processing/UCB-OCR"
for f in *
do
	vnm=${f%.xml}
	IFS='-'
	arr=($vnm)
	wnm="${arr[0]}"
	IFS=
	echo $wnm/$vnm
	mkdir -p $base/$wnm/$vnm
	cp $f $base/$wnm/$vnm/
done
