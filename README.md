# Aula: bancos de dados

Apresentação Marp com 52 slides e laboratório local para executar os exemplos da loja virtual. O Markdown é a fonte da apresentação; o PDF e o HTML já estão gerados.

## Apresentação

- `aula-bancos-de-dados-marp.md`: fonte e notas do professor.
- `index.html`: apresentação navegável, com notas e modo de apresentação do Marp. Abra no navegador; use as setas para navegar e `p` para o modo do apresentador.
- `aula-bancos-de-dados.pdf`: um slide por página, para leitura e compartilhamento.

Para regenerar os dois arquivos, com Docker em execução:

```bash
./scripts/gerar-slides.sh
```

A imagem oficial do [Marp CLI](https://github.com/marp-team/marp-cli) já contém o navegador necessário para a exportação. Não é preciso instalar Node ou Chrome no host.

## Executar os testes

Requisitos: Docker com Compose v2 ou posterior e Bash (Linux, macOS ou WSL). Execute os comandos nesta pasta. O primeiro uso baixa as imagens e constrói o executor Python.

```bash
# Opcional: ajustar credenciais e portas locais.
cp .env.example .env

# PostgreSQL, MongoDB, Redis, pgvector e SQLite.
./scripts/testar.sh

# Todas as tecnologias da aula, uma etapa por vez.
./scripts/testar.sh todos

# Apenas os cinco bancos opcionais.
./scripts/testar.sh opcionais

# Executar somente uma tecnologia.
./scripts/testar.sh postgres
./scripts/testar.sh vetorial
./scripts/testar.sh cassandra
./scripts/testar.sh neo4j
./scripts/testar.sh influxdb
./scripts/testar.sh clickhouse
./scripts/testar.sh elasticsearch
```

Também são aceitos `mongodb`, `redis` e `sqlite`. O executor encerra com código diferente de zero se houver falha. Os logs ficam em `resultados/testes-<grupo>.log`; planos, comparações, resultados JSON e o backup PostgreSQL ficam na mesma pasta.

O script inicia e aguarda o healthcheck do serviço necessário. Ao terminar cada etapa, ele para o serviço que iniciou. Serviços que já estavam ativos permanecem ativos. Os volumes preservam os dados. As cargas de teste recriam ou ajustam os objetos do laboratório; use uma execução por vez.

Os bancos mais pesados são opcionais no Compose. A execução sequencial permite usar `todos` sem manter todos os motores ativos ao mesmo tempo. Reserve aproximadamente 3 GB de memória livre e espaço para as imagens. Subir todos simultaneamente exige mais memória.

## Demonstração PostgreSQL durante a aula

```bash
./scripts/demonstrar-postgres.sh
```

Esse comando deixa o PostgreSQL ativo, prepara os mesmos 200 mil pedidos fictícios das notas e mostra `EXPLAIN (ANALYZE, BUFFERS)` antes e depois do índice composto. Os planos em texto ficam em `resultados/postgres-antes.txt` e `resultados/postgres-depois.txt`.

Os scripts SQL também podem ser executados separadamente:

```bash
./scripts/subir.sh postgres
docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d aula < laboratorio/postgres/01-preparar.sql
docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d aula < laboratorio/postgres/02-antes.sql
docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d aula < laboratorio/postgres/03-depois.sql
```

## O que os testes verificam

| Tecnologia | Verificações |
|---|---|
| PostgreSQL | 200 mil pedidos / mil clientes; mesmas linhas antes e depois do índice; JOIN; paginação por cursor; consultas parametrizadas; UNIQUE, NOT NULL, CHECK e chave estrangeira; rollback; duas conexões disputando uma unidade de estoque; backup restaurado em outra base e conferido por contagem e hash. |
| MongoDB | Atributos em documentos, filtro por categoria, ordenação por preço e preservação dos resultados após índice composto. Exibe o plano com estatísticas. |
| Redis | Cache por chave, TTL positivo, expiração efetiva, ranking com sorted set e política `allkeys-lru`. |
| Cassandra | Chave de partição por transportadora e dia, clustering temporal e consulta restrita à partição esperada. |
| Neo4j | Constraint no ponto inicial e travessia de dois relacionamentos para encontrar somente o cliente que compartilha um dispositivo. Usa labels `AulaCliente` e `AulaDispositivo`. |
| InfluxDB 3 Core | Escrita em lote, filtro por equipamento e janela temporal, contagem e média das três temperaturas do exemplo. |
| ClickHouse | MergeTree, inserção em lote, filtro por data e receita por categoria. |
| Elasticsearch | Mapping `text` / `keyword`, lote sem erros e busca textual com filtro exato após `refresh=wait_for`. |
| pgvector | Busca exata e HNSW com cosseno; medição de recall@5 para uma consulta. Usa vetores artificiais de dimensão 3. |
| SQLite | Banco embarcado sem servidor, rollback e restrição de estoque. |

Os planos e tempos são observações do ambiente. Os testes não exigem um tipo de plano, uma latência específica ou recall de 100%. Os vetores ilustrativos não avaliam relevância semântica. Cassandra usa um nó, e não há teste de partição de rede ou de CAP neste laboratório.

O executor PostgreSQL usa Psycopg com parâmetros; o slide de Node.js mostra a mesma separação entre SQL e valores usando `node-postgres`.

## Serviços e conexões

```bash
# Mantém o laboratório básico ativo para exploração manual.
./scripts/subir.sh

# Mantém apenas um banco opcional ativo.
./scripts/subir.sh neo4j

# Encerra os serviços e preserva os volumes.
./scripts/parar.sh
```

| Serviço | Acesso no host | Credenciais padrão / base |
|---|---|---|
| PostgreSQL + pgvector | `localhost:15432` | `aula` / `aula_local`; banco `aula`, schema `aula_db` |
| MongoDB | `mongodb://localhost:27018/aula` | Sem autenticação; coleção `produtos_aula` |
| Redis | `localhost:16379` | Sem autenticação; prefixo `aula:`; cache descartável |
| Cassandra | `localhost:19042` | Keyspace `aula` |
| Neo4j | <http://localhost:17474>; Bolt `localhost:17687` | `neo4j` / `aula_grafos_local` |
| InfluxDB 3 Core | <http://localhost:18086> | Sem autenticação; banco `aula`; SQL na API v3 |
| ClickHouse | <http://localhost:18123>; nativo `localhost:19000` | `aula` / `aula_local`; banco `aula` |
| Elasticsearch | <http://localhost:19200> | Sem autenticação; índice `aula-produtos` |

As portas são publicadas somente em `127.0.0.1`. As senhas e serviços sem autenticação são configurações para estudo local. Os exemplos trabalham com dados fictícios e volumes próprios deste projeto.

## Conferir o layout dos slides

```bash
docker compose run --rm --no-deps --entrypoint node marp scripts/verificar-slides.cjs
```

Verifica os 52 slides no navegador, identifica conteúdo ultrapassando o espaço disponível e salva `resultados/slides-layout.json`, além de capturas de cinco slides para inspeção. Execute depois de gerar o HTML.

## Referências de implementação

- [pgvector: instalação e Docker](https://github.com/pgvector/pgvector#docker)
- [InfluxDB 3 Core: instalação](https://docs.influxdata.com/influxdb3/core/install/)
- [Neo4j: Docker](https://neo4j.com/docs/operations-manual/current/docker/introduction/)
- [ClickHouse: Docker](https://clickhouse.com/docs/get-started/setup/self-managed/docker)

As demais referências técnicas e os limites de cada exemplo estão nos slides e nas notas do Markdown.
