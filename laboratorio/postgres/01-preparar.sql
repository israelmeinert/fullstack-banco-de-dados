-- Dados fictícios e determinísticos da aula. Execute somente no laboratório.
CREATE SCHEMA IF NOT EXISTS aula_db;
CREATE TABLE IF NOT EXISTS aula_db.pedidos_demo (
  id BIGINT PRIMARY KEY,
  cliente_id BIGINT NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL,
  total_centavos BIGINT NOT NULL CHECK (total_centavos >= 0)
);
INSERT INTO aula_db.pedidos_demo (id, cliente_id, criado_em, total_centavos)
SELECT n, ((n * 37) % 1000) + 1,
       TIMESTAMPTZ '2025-01-01 00:00:00+00' + n * INTERVAL '1 minute',
       1000 + (n % 100000)
FROM generate_series(1, 200000) AS s(n)
ON CONFLICT (id) DO NOTHING;
ANALYZE aula_db.pedidos_demo;

CREATE TABLE IF NOT EXISTS aula_db.clientes (
  id BIGINT PRIMARY KEY,
  nome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE
);
INSERT INTO aula_db.clientes
SELECT n, 'Cliente ' || n, 'cliente' || n || '@exemplo.test'
FROM generate_series(1, 1000) AS s(n)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS aula_db.produtos (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku TEXT NOT NULL UNIQUE,
  nome TEXT NOT NULL,
  estoque INTEGER NOT NULL CHECK (estoque >= 0)
);
-- OVERRIDING permite usar o mesmo id 42 do slide sem alterar o identity.
INSERT INTO aula_db.produtos (id, sku, nome, estoque)
OVERRIDING SYSTEM VALUE VALUES (42, 'MOCH-42', 'Mochila', 1)
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('aula_db.produtos', 'id'),
              (SELECT max(id) FROM aula_db.produtos));

CREATE TABLE IF NOT EXISTS aula_db.reservas (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  produto_id BIGINT NOT NULL REFERENCES aula_db.produtos(id),
  quantidade INTEGER NOT NULL CHECK (quantidade > 0)
);
