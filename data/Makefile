include Makefile_settings.txt


INSERTION_DONE = ../extraction/.inserted


# Location of cypher-shell executable
CYPHER_SHELL = $(N4J_DB_PATH)/bin/cypher-shell -a $(N4J_URI) -u $(N4J_USER) -p $(N4J_PASS) --format plain


DEBATE_LIST = stats/all_debates.csv

#MK_CSV = python3 create_csv.py --uri $(N4J_URI) --user $(N4J_USER) --passw $(N4J_PASS)
DEBATE_IDS := $(shell if test -f $(DEBATE_LIST); then tail -n +2 $(DEBATE_LIST) | cut -d ',' -f 1 | tr -d '"'; fi)


all: $(foreach d, $(DEBATE_IDS), debates/premises_$(d).csv debates/arguments_$(d).csv)
	-@test "$(DEBATE_IDS)" || echo "Please 'make debate_list' first"


debate_list: $(DEBATE_LIST)

stats: stats/per_debate.csv stats/per_website.csv




$(N4J_DB_PATH)/import/%: $(EXTRACTION_PATH)/%
	cp $^ $(N4J_DB_PATH)/import/

../extraction/.inserted:
	make -C $(dir $@) .inserted

.preprocessed: $(INSERTION_DONE)
	@echo "Preprocessing"
	$(CYPHER_SHELL) 'match (x:Debate) optional match (x)-[r:Contains]->() delete x, r return count(*) as deleted'
	$(CYPHER_SHELL) < cypher_scripts/update_graph.cql
	date > $@

.arginfered: $(INSERTION_DONE)
	@echo "Infer arguments"
	$(CYPHER_SHELL) 'match (x:Argument) optional match (x)-[r1:Premise|:Conclusion|:NegConclusion]->() optional match (x)-[r2:Attack|:Support]->(y:Argument) delete x, y, r1, r2 return count(*) as deleted'
	$(CYPHER_SHELL) < cypher_scripts/infer_arguments.cql
	date > $@

debates/premises_%.csv: .preprocessed | debates/
	$(CYPHER_SHELL) 'match (x:Debate)-[:Contains]->(y) where x.origin + x.n = "$*" with y match (y)-[r:Pro|:Cons]->(z) return y.label as premise, z.label as conclusion, r.w as weight' > $@

debates/arguments_%.csv: .arginfered .preprocessed | debates/
	$(CYPHER_SHELL) 'match (x:Debate)-[:Contains]->()<-[:Premise|:Conclusion|:NegConclusion]-(y:Argument) where x.origin + x.n = "$*" with y match (y)-[r:Attack|:Support]->(z) return y.key as arg1, z.key as arg2, type(r) as attack_support' > $@



$(DEBATE_LIST): .preprocessed | stats/
	$(CYPHER_SHELL) 'match (x:Debate)-[:Contains]->(y) return x.origin + x.n as key, count(y) as n_premises, x.title as title' > $@


stats/per_debate.csv: .preprocessed | stats/
	$(CYPHER_SHELL) < cypher_scripts/stats_per_debate.cql > $@

stats/per_website.csv: .preprocessed | stats/
	$(CYPHER_SHELL) < cypher_scripts/stats_per_website.cql > $@





stats/ debates/:
	mkdir -p $@



clean:
	rm -f $(DEBATE_LIST) debates/* .preprocessed .arginfered


.PHONY: all debate_list stats clean
.PRECIOUS: .inserted .preprocessed
