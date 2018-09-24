# This script was written to normalize eKanjur txt files from Ngawang Trinley
# but unfortunately there was so much variation that it was necessary to
# visit each file manually in bbedit.
#
# The script is checked in so that we have an example of the sort of script
# that is needed to handle Tibetan Unicode - awk and sed do NOT work since those
# tools are not UTF-8 aware. Further, perl doesn't play well with UTF-16 so the
# tool, iconv, is employed to convert from UTF-16 to UTF-8.
#
# There are further considerations of excluding a BOM and so on.


n=1
for f in * ; do
	fNm=${f%.txt}
	nf=${fNm// /-}-utf8.txt
	v="v$(printf %03d $n).txt"
	iconv -f UTF-16 -t UTF-8 "$f" > $nf
	perl -e 's/\[/\n[/g' -p "$nf" > $v 
	n=`expr $n + 1`
done
