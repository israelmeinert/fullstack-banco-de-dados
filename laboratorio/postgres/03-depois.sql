CREATE INDEX IF NOT EXISTS idx_pedidos_demo_cliente_data
ON aula_db.pedidos_demo (cliente_id, criado_em DESC, id DESC);
ANALYZE aula_db.pedidos_demo;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, criado_em, total_centavos
FROM aula_db.pedidos_demo
WHERE cliente_id = 42
ORDER BY criado_em DESC, id DESC
LIMIT 20;
