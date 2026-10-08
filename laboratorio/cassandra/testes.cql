CREATE KEYSPACE IF NOT EXISTS aula
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
CREATE TABLE IF NOT EXISTS aula.eventos_entrega (
  transportadora_id text,
  dia date,
  ocorrido_em timestamp,
  evento_id uuid,
  status text,
  PRIMARY KEY ((transportadora_id, dia), ocorrido_em, evento_id)
) WITH CLUSTERING ORDER BY (ocorrido_em DESC, evento_id ASC);
INSERT INTO aula.eventos_entrega (transportadora_id, dia, ocorrido_em, evento_id, status)
VALUES ('TR-01', '2025-01-01', '2025-01-01T10:00:00Z', 00000000-0000-0000-0000-000000000001, 'coletado');
INSERT INTO aula.eventos_entrega (transportadora_id, dia, ocorrido_em, evento_id, status)
VALUES ('TR-01', '2025-01-01', '2025-01-01T11:00:00Z', 00000000-0000-0000-0000-000000000002, 'entregue');
INSERT INTO aula.eventos_entrega (transportadora_id, dia, ocorrido_em, evento_id, status)
VALUES ('TR-02', '2025-01-01', '2025-01-01T12:00:00Z', 00000000-0000-0000-0000-000000000003, 'outra_transportadora');
SELECT status FROM aula.eventos_entrega
WHERE transportadora_id = 'TR-01' AND dia = '2025-01-01' LIMIT 20;
