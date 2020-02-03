
// Create arguments
MATCH
  (x:Sentence)-[:Pro]->(y:Sentence)
CREATE
  (x)<-[:Premise]-(:Argument {key: x.origin+x.n+" -> "+y.origin+y.n})-[:Conclusion]->(y)
RETURN
  count(*) as pro_args
;
MATCH
  (x:Sentence)-[:Cons]->(y:Sentence)
CREATE
  (x)<-[:Premise]-(:Argument {key: x.origin+x.n+" -> ¬"+y.origin+y.n})-[:NegConclusion]->(y)
RETURN
  count(*) as cons_args
;

// Infer support and attack relations (only those that are not symmetric)
MATCH
  (x:Argument)-[:Conclusion]->()<-[:Premise]-(y:Argument)
CREATE
  (x)-[:Support]->(y)
RETURN
  count(*) as support_edges
;
MATCH
  (x:Argument)-[:NegConclusion]->()<-[:Premise]-(y:Argument)
CREATE
  (x)-[:Attack]->(y)
RETURN
  count(*) as attack_edges
;
