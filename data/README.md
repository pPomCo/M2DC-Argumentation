# Data formatting

Extracted data are stored in a Neo4j graph database (see [extraction](../extraction/README.md). This package produces formatted CSVs.


## How to

Ensure that the [Makefile settings](Makefile_settings.txt) are OK, then run the following commands:

	# List of debates
	make debate_list
	
	# Pro/Cons and Attack/Support relations
	make
	
	# Some stats
	make stats
	
