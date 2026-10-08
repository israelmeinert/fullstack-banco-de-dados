CREATE TABLE IF NOT EXISTS aula.vendas_analiticas (
  id UInt64, categoria LowCardinality(String), data Date, valor_centavos UInt64
) ENGINE = MergeTree ORDER BY (data, categoria, id);
TRUNCATE TABLE aula.vendas_analiticas;
INSERT INTO aula.vendas_analiticas VALUES
  (1, 'informatica', '2025-01-01', 450000),
  (2, 'informatica', '2025-01-02', 350000),
  (3, 'acessorios', '2025-01-02', 15000),
  (4, 'informatica', '2024-12-31', 999999);
SELECT categoria, SUM(valor_centavos) AS receita
FROM aula.vendas_analiticas WHERE data >= '2025-01-01'
GROUP BY categoria ORDER BY categoria;
SELECT throwIf(count() != 2 OR sum(receita) != 815000,
               'Agregacao ou filtro temporal incorreto')
FROM (
  SELECT categoria, SUM(valor_centavos) AS receita
  FROM aula.vendas_analiticas WHERE data >= '2025-01-01'
  GROUP BY categoria
);
