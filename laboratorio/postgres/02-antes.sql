DROP INDEX IF EXISTS aula_db.idx_pedidos_demo_cliente_data;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, criado_em, total_centavos
FROM aula_db.pedidos_demo
WHERE cliente_id = 42
ORDER BY criado_em DESC, id DESC
LIMIT 20;
