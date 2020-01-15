#! /bin/sh

# Extract the argumentation graph of Arguman
# Usage: extract_wd.sh [fr|en|es|pl|tr|ch]


# Parse command-line arguments
usage() {
    echo "$0: usage: [fr|en|es|pl|tr|ch]" >&2
}
LANGUAGE=
case $# in
    0)
	LANGUAGE=fr
	;;
    1)
	LANGUAGE="$1"
	;;
    *)
	usage && exit 1
	;;
esac



# Globals
URL="https://$LANGUAGE.arguman.org"
SITEMAP="$URL"
OUTPUT_DIR="am-$LANGUAGE"
HASHMAP="$OUTPUT_DIR/hashmap.txt"



# Create CSVs' output directory
mkdir -p $OUTPUT_DIR

# Initialize hashmap
echo -n "" >> $HASHMAP



# Function: get numerical id from url (and append it to the hashmap, if necessary)
url2id() { # $1=url
    grep '^'"$1"';' $HASHMAP > /dev/null 2>&1
    code=$?
    if test $code -eq 0
    then
	grep '^'"$1"';' $HASHMAP | cut -d ';' -f 2
    else
	n=`cat $HASHMAP | wc -l`
	echo "$1;$n" >> $HASHMAP
	echo $n
    fi
}

# Function: get url from numerical id
id2url() { # $1=id
    grep ';'"$1"'$' $HASHMAP | cut -d ';' -f 2
}





# Download and convert the sitemap
echo "Extract sitemap: $SITEMAP"
wget -q $SITEMAP -O - \
    | grep '<h3>' \
    | tr ';' '~' \
    | sed 's/^.*href=".\(.*\)">\(.*\)<.a>.*$/\1;\2;0/' \
    | tr '"' "'" > $OUTPUT_DIR/sitemap.csv


# Download and convert first-level arguments (i.e. debate pages)
urls=`cat $OUTPUT_DIR/sitemap.csv | cut -d ';' -f 1`
for url in $urls; 
do
    fname="$OUTPUT_DIR/`url2id "$url"`.csv"
    if test ! -f "$fname"
    then
	echo "Extract main page: $fname: $url"
	wget -q "$URL/$url" -O - \
	    | tr -d '\n'  \
	    | sed 's/^.*\(<ul.*data-level="1".*<.ul>\)<.div><.div><div id="list-view-indicator" class="tooltip">.*$/\1/' \
	    | xsltproc xslt/am_page.xsl - \
	    | sed "s/--place-url-here--/$url/" \
	    | tr '"' "'" > $fname
    fi
done


# Download and convert all pages (iterate until no new page is downloaded)
n_files1=0
n_files2=`ls $OUTPUT_DIR/*.csv | wc -w`
i=1
while test $n_files1 -ne $n_files2
do 
    urls=`cat $OUTPUT_DIR/*.csv | cut -d ';' -f 1`
    for url in $urls
    do 
	if test ! -f $OUTPUT_DIR/`url2id $url`.csv
	then
	    echo "i=$i. Extract page: $url"
	    base_url="`echo "$url" | sed 's/?.*$//'`"
	    wget -q "$URL/$url" -O - \
		| tr -d '\n' \
		| sed 's/^.*\(<ul.*data-level="1".*<.ul>\).*$/\1/' \
		| xsltproc xslt/am_page.xsl - \
		| sed "s/--place-url-here--/$base_url/" \
		| tr '"' "'" > $OUTPUT_DIR/`url2id "$url"`.csv
	fi
    done
    n_files1=$n_files2
    n_files2=`ls $OUTPUT_DIR/*.csv | wc -w`
    i=`expr $i + 1`
done


# Build the wd_nodes.csv and wd_edges.csv graph representation
echo "Create '${OUTPUT_DIR}_nodes.csv' and '${OUTPUT_DIR}_edges.csv'"
python3 mk_graph.py $OUTPUT_DIR --hashmap $HASHMAP


# Generate the Cypher insertion instructions for Neo4j
echo "Generate insert instructions (cypher)"
f=${OUTPUT_DIR}_insertion.cql
echo "//Auto-generated insertion instructions." > $f
tail -n +3 insertion_template.cql | sed "s/xxx/$OUTPUT_DIR/g" >> $f
