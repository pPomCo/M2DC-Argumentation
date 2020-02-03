
MATCH
  (x: Sentence)
WHERE
  not (x)-->(:Sentence)
CREATE
  (:Debate {origin: x.origin, n: x.n, title: x.label})-[:Contains {depth: 0}]->(x)
;


CALL
  apoc.periodic.commit(
    "MATCH (x:Sentence)-[r:Pro|:Cons]->(y:Sentence)<-[s:Contains]-(z:Debate) WHERE not (x)<-[:Contains]-(z) WITH x, z, min(s.depth) + 1 as d CREATE (x)<-[:Contains {depth: d}]-(z) RETURN count(*) LIMIT 1",
    {limit: 100}
  )
;
