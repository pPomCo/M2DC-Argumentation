MATCH
  (x:Debate)-[r:Contains]->(y:Sentence)
WITH
  x.origin as origin,
  r.depth as depth,
  y
OPTIONAL MATCH
  (y)-[:Pro]->(z)
WITH
  origin, depth, y,
  count(z) as out_pro_deg
OPTIONAL MATCH
  (y)-[:Cons]->(z)
WITH
  origin, depth, y,
  out_pro_deg,
  count(z) as out_cons_deg
OPTIONAL MATCH
  (z)-[:Pro]->(y)
WITH
  origin, depth, y,
  out_pro_deg,
  out_cons_deg,
  count(z) as in_pro_deg
OPTIONAL MATCH
  (z)-[:Cons]->(y)
WITH
  origin, depth, y,
  out_pro_deg,
  out_cons_deg,
  in_pro_deg,
  count(z) as in_cons_deg
RETURN
  origin,
  count(y) as n_sentences,
  sum(out_pro_deg) as n_pro_relations,
  sum(out_cons_deg) as n_cons_relations,
  avg(out_pro_deg) as avg_out_pro_deg,
  avg(out_cons_deg) as avg_out_cons_deg,
  max(out_pro_deg) as max_out_pro_deg,
  max(out_cons_deg) as max_out_cons_deg,
  avg(in_pro_deg) as avg_in_pro_deg,
  avg(in_cons_deg) as avg_in_cons_deg,
  max(in_pro_deg) as max_in_pro_deg,
  max(in_cons_deg) as max_in_cons_deg,
  avg(depth) as avg_depth,
  max(depth) as max_depth,
  min(size(y.label)) as min_label_size,
  avg(size(y.label)) as avg_label_size,
  max(size(y.label)) as max_label_size,
  min(size(y.description)) as min_descr_size,
  avg(size(y.description)) as avg_descr_size,
  max(size(y.description)) as max_descr_size
;
