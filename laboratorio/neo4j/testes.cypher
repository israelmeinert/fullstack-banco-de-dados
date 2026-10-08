CREATE CONSTRAINT aula_cliente_id IF NOT EXISTS
FOR (c:AulaCliente) REQUIRE c.id IS UNIQUE;
MATCH (n:AulaCliente) DETACH DELETE n;
MATCH (n:AulaDispositivo) DETACH DELETE n;
CREATE (a:AulaCliente {id:42}), (b:AulaCliente {id:7}), (c:AulaCliente {id:99}),
       (d:AulaDispositivo {id:'compartilhado'}), (e:AulaDispositivo {id:'isolado'}),
       (a)-[:USA]->(d), (b)-[:USA]->(d), (c)-[:USA]->(e);
:param id => 42;
MATCH (c:AulaCliente {id:$id})-[:USA]->(d:AulaDispositivo)<-[:USA]-(outro:AulaCliente)
WHERE outro <> c
RETURN DISTINCT outro.id AS cliente_relacionado LIMIT 20;
