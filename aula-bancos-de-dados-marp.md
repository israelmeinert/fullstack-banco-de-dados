---
marp: true
theme: default
size: 16:9
paginate: true
lang: pt-BR
title: "Bancos de dados — modelos, escolhas e desempenho"
description: "Tipos e propósitos de bancos de dados, critérios de escolha, CAP, boas práticas e otimização."
footer: "Bancos de dados · modelos, escolhas e desempenho"
style: |
  section {
    background: #f5f7fb;
    color: #20344a;
    font-family: "Aptos", "Segoe UI", Arial, sans-serif;
    font-size: 28px;
    line-height: 1.32;
    padding: 60px 64px 54px;
    justify-content: flex-start;
  }
  h1 {
    color: #102a43;
    font-size: 43px;
    line-height: 1.12;
    letter-spacing: -1px;
    margin: 0 0 26px;
  }
  h2 { color: #12657a; font-size: 31px; margin: 8px 0 18px; }
  p { margin: 0 0 18px; }
  strong { color: #0c6074; }
  a { color: #12657a; text-decoration: none; }
  ul, ol { margin: 0 0 18px; padding-left: 1.12em; }
  li { margin: 0 0 12px; }
  li > p { margin-bottom: 8px; }
  blockquote {
    border-left: 5px solid #16a6a1;
    background: #e7eff6;
    color: #173b52;
    margin: 12px 0 20px;
    padding: 16px 22px;
    font-size: 27px;
  }
  blockquote p { margin: 0; }
  code { font-family: "Consolas", "DejaVu Sans Mono", monospace; font-size: 0.88em; }
  :not(pre) > code { background: #e5ebf2; color: #173b52; padding: 2px 6px; border-radius: 4px; }
  pre {
    color: #20344a;
    background: #eaf0f6;
    border: 1px solid #d5dfe8;
    border-radius: 10px;
    padding: 18px 22px;
    margin: 4px 0 22px;
    font-size: 23px;
    line-height: 1.25;
  }
  pre code { font-size: 1em; line-height: 1.25; }
  table { width: 100%; font-size: 24px; border-collapse: collapse; margin: 4px 0 22px; }
  th { background: #16394d; color: #fff; font-weight: 600; }
  th, td { border: 1px solid #d5dfe8; padding: 12px 15px; text-align: left; }
  tr { background: #ffffff; }
  tr:nth-child(even) { background: #eaf0f6; }
  h6 {
    color: #607286;
    font-size: 14px;
    line-height: 1.35;
    font-weight: 400;
    margin: auto 0 0;
    padding-top: 12px;
  }
  h6 a { color: #4b7084; }
  header, footer { color: #6a7e91; font-size: 14px; }
  footer { bottom: 18px; }
  section::after { color: #6a7e91; font-size: 15px; bottom: 16px; }
  section.compact { font-size: 26px; }
  section.compact table { font-size: 22px; }
  section.compact th, section.compact td { padding: 8px 12px; }
  section.compact pre { font-size: 21px; }
  section.compact li { margin-bottom: 10px; }
  section.lead { background: #102b40; color: #eef5fa; justify-content: center; }
  section.lead h1 { color: #ffffff; font-size: 64px; line-height: 1.08; margin-bottom: 30px; }
  section.lead h2 { color: #6de0ce; font-size: 31px; }
  section.lead p { color: #d8e4ed; font-size: 29px; max-width: 1000px; }
  section.lead strong { color: #6de0ce; }
  section.lead footer, section.lead::after { color: #adc3d3; }
  section.lead blockquote { background: #173c53; color: #eef5fa; }
  section.references { font-size: 23px; }
  section.references table { font-size: 22px; }
  section.references th, section.references td { padding: 10px 12px; }
---

<!-- _class: lead -->

# Bancos de dados
## Escolher pelo problema, não pela ferramenta

Modelos, propósitos, garantias e desempenho.

**Uma loja virtual. Várias perguntas. Diferentes necessidades.**

<!--
NOTAS DO PROFESSOR
Apresente a loja como cenário fictício, não como uma arquitetura a ser implementada com todos os bancos citados. A proposta é aprender a justificar escolhas, não memorizar marcas.

USO DO ARQUIVO
Abra este Markdown no VS Code com a extensão Marp for VS Code e utilize a prévia Marp. O tema e os estilos estão incorporados. Os comentários são notas de apresentação, não conteúdo visível nos slides. Não há dependência de imagens externas, Mermaid ou HTML de layout.

Os exemplos de cada tecnologia são independentes e pressupõem os dados e as tabelas indicados. O bloco de preparação completo da demonstração PostgreSQL está nas notas do slide "Demonstração: investigue antes de alterar". Não execute os exemplos em produção.
-->

---

# Nosso desafio: a loja virtual

| Necessidade | Pergunta do negócio |
|---|---|
| Pedidos e estoque | Podemos confirmar esta compra? |
| Catálogo e busca | Qual produto atende à necessidade do cliente? |
| Eventos e medições | O que aconteceu e como os valores evoluíram? |
| Relatórios e conexões | Como estão as vendas? Há relações suspeitas? |

> O mesmo domínio pode exigir formas diferentes de consultar os dados.

<!--
NOTAS DO PROFESSOR
Pergunte qual banco a turma escolheria antes de discutir os requisitos. Anote mentalmente as justificativas e retome no encerramento. Não confirme uma ferramenta como vencedora neste momento. O percurso da aula vai de persistência e garantias aos tipos, à escolha, ao CAP e às boas práticas.
-->

---

# Por que não salvar tudo em JSON?

Imagine **uma unidade em estoque** e duas compras simultâneas.

- Quem coordena as alterações feitas ao mesmo tempo?
- O que acontece se o processo cair no meio da gravação?
- Como localizar pedidos sem ler e processar todo o arquivo?

Um gerenciador de banco oferece mecanismos de **consulta, concorrência, integridade e recuperação**.

> Persistir é apenas parte do problema.

###### Fontes: [PostgreSQL · transações](https://www.postgresql.org/docs/current/tutorial-transactions.html) · [PostgreSQL · constraints](https://www.postgresql.org/docs/current/ddl-constraints.html) · [PostgreSQL · backup e restauração](https://www.postgresql.org/docs/current/backup.html)

<!--
NOTAS DO PROFESSOR
Explore o problema, não demonize arquivos. Seria possível implementar mecanismos sobre arquivos, mas a aplicação assumiria responsabilidades normalmente oferecidas pelo gerenciador. Banco de dados não elimina falhas nem protege regras que nunca foram implementadas. As garantias concretas dependem do produto e da configuração.
-->

---

<!-- _class: compact -->

# Transações: o significado de ACID

| Propriedade | O que precisamos garantir |
|---|---|
| **Atomicidade** | Confirmar o conjunto de alterações ou desfazê-lo. |
| **Consistência** | Preservar as regras e invariantes definidos. |
| **Isolamento** | Controlar a interação entre transações concorrentes. |
| **Durabilidade** | Preservar o que foi confirmado, conforme as garantias configuradas. |

> Uma transação não corrige, sozinha, toda condição de corrida.

###### Fontes: [PostgreSQL · transações](https://www.postgresql.org/docs/current/tutorial-transactions.html) · [PostgreSQL · isolamento](https://www.postgresql.org/docs/current/transaction-iso.html)

<!--
NOTAS DO PROFESSOR
Use o registro do pedido junto da reserva de estoque como exemplo de unidade de trabalho. A aplicação e as restrições participam da preservação das regras. Não apresente isolamento como se todas as transações fossem sempre serializáveis; existem níveis com garantias distintas. Mais adiante, o C de ACID será diferenciado do C de CAP.
-->

---

# Banco não significa servidor separado

| Opção | Cenário para avaliação |
|---|---|
| Arquivo de configuração | Poucos dados, leitura simples, alterações controladas. |
| **SQLite embarcado** | Aplicação local que precisa de SQL e transações. |
| Banco cliente-servidor | Aplicações e usuários compartilhando dados pela rede. |

**SQLite é um banco relacional**, mesmo sem um serviço independente.

> Escolha a complexidade necessária, não a maior arquitetura possível.

###### Fontes: [SQLite · quando usar](https://sqlite.org/whentouse.html)

<!--
NOTAS DO PROFESSOR
Apresente um aplicativo desktop ou uma aplicação local como exemplo de uso do SQLite. Não confunda embarcado com banco de brinquedo. Em cenários com muitos escritores concorrentes ou acesso direto pela rede, avalie um banco cliente-servidor. Arquivos continuam apropriados quando seus limites são compatíveis com o problema.
-->

---

<!-- _class: lead -->

# Tipos de banco
## O modelo deve servir ao acesso

Para cada tipo, vamos perguntar:

**Para que serve? Onde ajuda? Qual é o limite? Como otimizar?**

<!--
NOTAS DO PROFESSOR
Este é o bloco principal. Mantenha os exemplos no contexto da loja e trate as otimizações como formas de reduzir trabalho para uma carga específica. Não aprofunde instalação nem administração de todos os produtos.
-->

---

# Não existe apenas “SQL versus NoSQL”

| Perspectiva | Exemplos de classificação |
|---|---|
| **Modelo de dados** | Relacional, documental, chave-valor, grafo. |
| **Organização de armazenamento** | Orientado a linhas ou a colunas. |
| **Carga de trabalho** | Transacional, analítica, temporal ou busca. |

Um produto pode aparecer em **mais de uma categoria**.

PostgreSQL armazena JSON. ClickHouse utiliza SQL e armazenamento colunar.

###### Fontes: [PostgreSQL · JSON](https://www.postgresql.org/docs/current/datatype-json.html) · [ClickHouse · armazenamento colunar](https://clickhouse.com/docs/get-started/about/intro)

<!--
NOTAS DO PROFESSOR
Explique que a classificação da aula mistura intencionalmente modelos e especializações práticas. Isso evita vender uma falsa separação entre mundos. Também não deduza garantias de transação ou desempenho apenas da presença da linguagem SQL.
-->

---

# Relacional: entidades e regras

**Exemplos:** PostgreSQL, MySQL, SQL Server e SQLite.

```text
clientes  →  pedidos  →  itens_pedido  ←  produtos
```

**Propósito:** relacionar entidades e proteger alterações com regras explícitas.

**Na loja:** clientes, pedidos, pagamentos registrados e estoque.

**Ponto forte:** transações e integridade referencial.
**Cuidado:** esquema bem definido não garante consultas eficientes.

###### Fontes: [PostgreSQL · constraints](https://www.postgresql.org/docs/current/ddl-constraints.html) · [PostgreSQL · EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html)

<!--
NOTAS DO PROFESSOR
As setas representam associações conceituais, não um diagrama completo de cardinalidade. Peça exemplos de regras que cruzam entidades. A existência de tabelas não dispensa a definição das chaves e restrições. Trate os produtos citados como exemplos da categoria, não como equivalentes em todos os recursos.
-->

---

<!-- _class: compact -->

# Relacional: combinar informações

“Quais são os últimos pedidos deste cliente?”

```sql
SELECT p.id, p.criado_em, c.nome
FROM pedidos AS p
JOIN clientes AS c ON c.id = p.cliente_id
WHERE p.cliente_id = 42
ORDER BY p.criado_em DESC, p.id DESC
LIMIT 20;
```

**Otimização:** investigar plano, volume processado e índices para os filtros e a ordenação.

> JOIN não é defeito. Trabalho desnecessário é o problema.

###### Fontes: [PostgreSQL · EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html) · [PostgreSQL · índices compostos](https://www.postgresql.org/docs/current/indexes-multicolumn.html)

<!--
NOTAS DO PROFESSOR
O exemplo pressupõe as tabelas clientes e pedidos da loja. Percorra FROM, JOIN, WHERE, ORDER BY e LIMIT pela intenção de cada cláusula, sem transformar o bloco em uma aula completa de SQL. O plano pode escolher estratégias diferentes de junção conforme os dados. Não prometa que acrescentar índices sempre melhora uma consulta.
-->

---

<!-- _class: compact -->

# Relacional: modelagem e otimização

| Decisão | Raciocínio |
|---|---|
| **Normalizar** | Reduzir repetição de fatos e inconsistências. |
| **Preservar um histórico** | Guardar no item o preço praticado na compra. |
| **Criar um índice composto** | Atender uma consulta, não uma coluna isolada. |

Um índice em `(cliente_id, criado_em)` **não equivale** a dois índices separados.

Índices também ocupam espaço e precisam ser mantidos nas gravações.

###### Fontes: [Cassandra · modelagem](https://cassandra.apache.org/doc/latest/cassandra/developing/data-modeling/intro.html) · [PostgreSQL · índices compostos](https://www.postgresql.org/docs/current/indexes-multicolumn.html) · [PostgreSQL · índices](https://www.postgresql.org/docs/current/indexes.html)

<!--
NOTAS DO PROFESSOR
O preço histórico do item é um fato diferente do preço atual do catálogo; não é simplesmente uma duplicação incorreta. Desnormalização deliberada deve ter uma regra clara de manutenção. Para índices B-tree compostos, a ordem das colunas importa, mas não ensine a regra absoluta de que o índice nunca pode ser usado sem a primeira coluna: detalhes do otimizador e da versão importam.
-->

---

<!-- _class: compact -->

# Documental: um conjunto em um documento

**Exemplo:** MongoDB. **Na loja:** catálogo com atributos variáveis.

```json
{
  "sku": "NOTE-001",
  "categoria": "informatica",
  "preco_centavos": 450000,
  "atributos": {
    "memoria_gb": 16,
    "armazenamento_gb": 512
  }
}
```

**Ponto forte:** reunir dados acessados juntos em uma estrutura flexível.

###### Fontes: [MongoDB · modelagem](https://www.mongodb.com/docs/manual/data-modeling/best-practices/)

<!--
NOTAS DO PROFESSOR
Compare o documento do notebook com o de uma camiseta. Não diga que um relacional seria incapaz de armazenar esses atributos: o exemplo serve para apresentar a representação documental. Dados monetários foram representados em centavos por simplicidade didática, sem esgotar modelagem de moedas, precisão ou arredondamentos.
-->

---

<!-- _class: compact -->

# Documental: incorporar ou referenciar?

**Incorpore** dados lidos juntos e com crescimento controlado.
**Referencie** dados independentes, compartilhados ou que crescem sem limite.

```javascript
db.produtos.createIndex({ categoria: 1, preco_centavos: 1 });
db.produtos.find({ categoria: "informatica" })
  .sort({ preco_centavos: 1 }).limit(20);
```

**Otimização:** evite documentos gigantes; combine consulta e índice.

> Esquema flexível não significa ausência de modelagem.

###### Fontes: [MongoDB · modelagem](https://www.mongodb.com/docs/manual/data-modeling/best-practices/) · [MongoDB · índices e ESR](https://www.mongodb.com/docs/manual/tutorial/equality-sort-range-guideline/)

<!--
NOTAS DO PROFESSOR
Pergunte por que guardar para sempre todas as compras no documento do cliente é arriscado. No exemplo do índice, categoria é igualdade e preço atende à ordenação. A diretriz ESR significa igualdade, ordenação e intervalo; intervalos muito seletivos podem justificar outra ordem. MongoDB tem validação de esquema e transações entre documentos; não apresente NoSQL como ausência de garantias.
-->

---

# Chave-valor: acesso por uma chave conhecida

**Exemplo:** Redis.

```text
produto:42:resumo  →  {"nome":"Mochila"}
```

**Propósito:** recuperar e atualizar valores por identificadores diretos.

**Na loja:** cache, contadores e rankings.

Redis também oferece hashes, conjuntos e conjuntos ordenados.

**Limite:** consultas com muitas relações exigem outras estruturas ou recursos.

###### Fontes: [Redis · tipos de dados](https://redis.io/docs/latest/develop/data-types/)

<!--
NOTAS DO PROFESSOR
Diferencie o modelo chave-valor da ideia de que todos os valores precisam ser strings. Use ranking para ilustrar que escolher uma estrutura nativa adequada pode evitar processamento na aplicação. Evite a afirmação absoluta de que o produto só serve para cache ou nunca pode oferecer recursos de busca.
-->

---

<!-- _class: compact -->

# Redis: desempenho exige política de dados

- Para cache, defina **expiração, limite de memória e eviction**.
- Use a estrutura certa e acompanhe acertos e falhas do cache.
- Avalie **pipelining** para reduzir viagens de rede.

**Pipelining não é uma transação atômica.**

Redis oferece persistência, mas cache descartável e dado durável exigem decisões diferentes.

> Se este cache desaparecer, conseguimos reconstruí-lo?

###### Fontes: [Redis · eviction](https://redis.io/docs/latest/develop/reference/eviction/) · [Redis · pipelining](https://redis.io/docs/latest/develop/using-commands/pipelining/) · [Redis · persistência](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)

<!--
NOTAS DO PROFESSOR
Explique eviction como remoção de chaves para respeitar a política de memória. TTL e eviction respondem a necessidades diferentes: validade temporal e pressão de memória. A expiração não substitui uma estratégia de atualização ou invalidação. Mencione que políticas agressivas para cache não devem ser aplicadas indiscriminadamente a dados que não podem ser perdidos.
-->

---

<!-- _class: compact -->

# Wide-column: a consulta orienta o modelo

**Exemplo:** Apache Cassandra.

**Propósito:** distribuir dados e atender padrões de acesso conhecidos.

**Na loja:** eventos de entrega por transportadora e período.

Trecho ilustrativo de chave primária em CQL:

```sql
PRIMARY KEY ((transportadora_id, dia), ocorrido_em, evento_id)
```

A **chave de partição** distribui os dados; as demais colunas da chave organizam os registros na partição.

###### Fontes: [Cassandra · modelagem](https://cassandra.apache.org/doc/latest/cassandra/developing/data-modeling/intro.html)

<!--
NOTAS DO PROFESSOR
O fragmento não é um CREATE TABLE completo. A janela diária é apenas uma hipótese: a carga real deve determinar o tamanho da janela e a distribuição. Uma partição muito movimentada pode concentrar trabalho mesmo quando o cluster tem vários nós. O aluno deve perceber que uma nova pergunta pode exigir outra tabela.
-->

---

<!-- _class: compact -->

# Wide-column: limites e otimizações

**Otimização:** distribuir a carga, limitar o tamanho das partições e consultar poucas partições.

**Cuidado:** no Cassandra, não há joins relacionais; diferentes consultas podem exigir duplicação de dados.

| Wide-column | Colunar analítico |
|---|---|
| Exemplo: Cassandra. | Exemplo: ClickHouse. |
| Acesso orientado por chaves e partições. | Leitura de colunas para grandes análises. |

> O nome parecido não significa o mesmo propósito.

###### Fontes: [Cassandra · modelagem](https://cassandra.apache.org/doc/latest/cassandra/developing/data-modeling/intro.html) · [ClickHouse · armazenamento colunar](https://clickhouse.com/docs/get-started/about/intro)

<!--
NOTAS DO PROFESSOR
Não reduza a diferença a um rótulo físico; compare as consultas para as quais os motores são projetados. Explique o custo de manter cópias de uma entidade em tabelas destinadas a acessos distintos. Volte à pergunta de negócio antes de discutir capacidade de escrita.
-->

---

# Grafos: as conexões são parte da resposta

**Exemplo:** Neo4j.

```text
(Cliente A) ──USA──> (Dispositivo) <──USA── (Cliente B)
```

**Propósito:** representar entidades e percorrer seus relacionamentos.

**Na loja:** investigar contas que compartilham dispositivos ou endereços.

**Ponto forte:** responder perguntas sobre caminhos e conexões.

> Ter relacionamentos não basta para justificar um banco de grafos.

###### Fontes: [Neo4j · conceitos](https://neo4j.com/docs/getting-started/appendix/graphdb-concepts/)

<!--
NOTAS DO PROFESSOR
Compartilhar um dispositivo não prova fraude. O exemplo mostra uma pista para investigação, não uma decisão automática sobre pessoas. Diferencie buscar uma associação simples de percorrer redes de conexões. No relacional também existem relacionamentos; o diferencial está no padrão de consulta.
-->

---

<!-- _class: compact -->

# Grafos: limite o trabalho da travessia

```cypher
MATCH (c:Cliente {id: $id})-[:USA]->(d:Dispositivo)
      <-[:USA]-(outro:Cliente)
WHERE outro <> c
RETURN DISTINCT outro.id
LIMIT 20;
```

**Otimização:** indexe o ponto de partida, use relações específicas e limite caminhos e resultados.

**Cuidado:** uma travessia sem limites pode explorar uma parte enorme do grafo.

###### Fontes: [Neo4j · otimização de consultas](https://neo4j.com/docs/cypher-manual/current/planning-and-tuning/query-tuning/)

<!--
NOTAS DO PROFESSOR
O exemplo usa dois relacionamentos fixos e pressupõe o parâmetro id. Discuta um índice ou constraint para Cliente.id. Limitar o resultado não torna todo plano barato: filtros, ponto de partida e expansão continuam importantes. A ferramenta PROFILE ajuda a verificar o trabalho realizado; não aprofunde a sintaxe de Cypher.
-->

---

<!-- _class: compact -->

# Séries temporais: valores ao longo do tempo

**Exemplo:** InfluxDB.

| Instante | Equipamento | Temperatura |
|---|---|---|
| 10:00 | câmara-01 | 3,2 °C |
| 10:01 | câmara-01 | 3,4 °C |
| 10:02 | câmara-01 | 3,3 °C |

**Na loja:** acompanhar equipamentos do centro de distribuição.

**Pergunta:** como a temperatura evoluiu em cada intervalo?

**Modelo:** instante + identificação da série + valores medidos.

###### Fontes: [InfluxDB · modelagem](https://docs.influxdata.com/influxdb3/core/write-data/best-practices/schema-design/)

<!--
NOTAS DO PROFESSOR
Os horários são dados do exemplo, não marcações de duração da aula. Explique a importância de saber a unidade e a origem da medida. Dados associados a tempo também podem existir em outros bancos; o critério é a relevância dessa carga de ingestão e consulta para o projeto.
-->

---

# Séries temporais: retenção e agregação

- Consulte **janelas de tempo**, não todo o histórico por padrão.
- Separe identificação da série e valores medidos.
- Avalie escrita em lote e a precisão temporal necessária.

**Decisão de projeto:** manter medições detalhadas recentes e resumos antigos pode reduzir volume e trabalho.

**Cuidado:** recomendações de modelagem variam entre motores e versões.

###### Fontes: [InfluxDB · modelagem](https://docs.influxdata.com/influxdb3/core/write-data/best-practices/schema-design/) · [InfluxDB · otimização de escrita](https://docs.influxdata.com/influxdb3/core/write-data/best-practices/optimize-writes/)

<!--
NOTAS DO PROFESSOR
Proponha comparar guardar cada medição para sempre com manter agregações mais antigas. Retenção e resumos devem preservar o que o negócio ainda precisa explicar; não descarte dados sem essa decisão. No InfluxDB, tags representam metadados e fields representam medições. Não repita indiscriminadamente recomendações de cardinalidade de gerações anteriores: o mecanismo de armazenamento mudou.
-->

---

<!-- _class: compact -->

# Colunar analítico: analisar muitos registros

**Exemplo:** ClickHouse.

| OLTP — operacional | OLAP — analítico |
|---|---|
| Confirmar uma compra. | Somar vendas de todo o histórico. |
| Alterar poucos registros. | Agregar grandes conjuntos. |
| Operações do dia a dia. | Indicadores e exploração de dados. |

Armazenamento colunar favorece a leitura das **colunas necessárias** à análise.

> SQL é uma linguagem. OLTP e OLAP descrevem cargas de trabalho.

###### Fontes: [ClickHouse · armazenamento colunar](https://clickhouse.com/docs/get-started/about/intro)

<!--
NOTAS DO PROFESSOR
Use uma tabela com muitas colunas e uma consulta que só precisa de categoria, data e valor. O benefício é evitar ler campos irrelevantes e explorar a organização voltada a análise. Não afirme que um sistema OLTP nunca faz relatórios; a separação passa a importar conforme o volume, a concorrência e os objetivos.
-->

---

<!-- _class: compact -->

# Colunar: leia menos, grave em lotes

```sql
SELECT categoria, SUM(valor_centavos) AS receita
FROM vendas_analiticas
WHERE data >= '2025-01-01'
GROUP BY categoria;
```

**Otimização no ClickHouse:** alinhar a chave de ordenação aos filtros, selecionar as colunas necessárias e agrupar inserções.

**Cuidado:** otimizar grandes análises não significa substituir automaticamente o banco que confirma pedidos.

###### Fontes: [ClickHouse · chave de ordenação](https://clickhouse.com/docs/concepts/best-practices/choosing-a-primary-key) · [ClickHouse · estratégias de inserção](https://clickhouse.com/docs/concepts/best-practices/selecting-an-insert-strategy)

<!--
NOTAS DO PROFESSOR
A tabela é hipotética e serve para demonstrar a carga analítica. No ClickHouse, não confunda a chave usada para ordenação e busca com uma garantia automática de unicidade equivalente à chave primária de um banco relacional tradicional. A estratégia de gravação deve considerar o custo de muitas inserções pequenas.
-->

---

<!-- _class: compact -->

# Motores de busca: texto e relevância

**Exemplo:** Elasticsearch.

**Propósito:** encontrar e ordenar resultados a partir de conteúdo textual e critérios de pesquisa.

**Na loja:** procurar “mochila para notebook” no catálogo.

| Busca exata | Busca textual |
|---|---|
| Encontrar o SKU `MOCH-42`. | Encontrar descrições relevantes. |
| Comparar um identificador. | Analisar termos e calcular relevância. |

**Cuidado:** uma alteração pode não aparecer imediatamente na busca.

###### Fontes: [Elasticsearch · campos text](https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/text) · [Elasticsearch · busca quase em tempo real](https://www.elastic.co/docs/manage-data/data-store/near-real-time-search)

<!--
NOTAS DO PROFESSOR
Explique que a análise textual transforma o conteúdo em termos e influencia o que pode ser encontrado. No exemplo de arquitetura da aula, o índice de busca é uma representação derivada do catálogo. Não o apresente como fonte obrigatória de verdade para transações. A visibilidade de alterações depende do refresh.
-->

---

<!-- _class: compact -->

# Busca: modelagem também é otimização

```json
{
  "properties": {
    "nome": { "type": "text" },
    "categoria": { "type": "keyword" }
  }
}
```

**Otimização:** use tipos adequados, indexação em lote e uma frequência de refresh compatível com a necessidade de atualização.

**Decisão da loja:** o índice pode ser reconstruído a partir da fonte principal.

###### Fontes: [Elasticsearch · campos text](https://www.elastic.co/docs/reference/elasticsearch/mapping-reference/text) · [Elasticsearch · indexação](https://www.elastic.co/docs/deploy-manage/production-guidance/optimize-performance/indexing-speed)

<!--
NOTAS DO PROFESSOR
O código é o conteúdo do mapping, não uma requisição REST completa. Nome é texto para análise; categoria é um valor para comparações estruturadas. A frequência de refresh representa uma troca entre atualização da busca e custo de indexação. Não confunda ficar visível para busca com a durabilidade do dado.
-->

---

# Vetorial: buscar por proximidade

**Exemplo:** PostgreSQL com a extensão pgvector.

```text
Texto ou imagem → modelo de embeddings → vetor → busca
```

**Propósito:** localizar representações numericamente semelhantes.

**Na loja:** recomendar itens próximos ao significado de uma descrição.

**Ponto forte:** busca por similaridade além da igualdade de palavras.

**Limite:** similaridade não comprova verdade nem relevância para o negócio.

###### Fontes: [pgvector · documentação](https://github.com/pgvector/pgvector)

<!--
NOTAS DO PROFESSOR
O modelo de embeddings transforma conteúdo em uma representação; o banco executa a busca sobre essa representação. Um índice vetorial não gera os embeddings por conta própria. A qualidade deve ser avaliada com consultas e resultados do domínio. Evite prometer que o banco compreende semanticamente qualquer dado independentemente do modelo escolhido.
-->

---

<!-- _class: compact -->

# Vetorial: velocidade versus recall

```sql
SELECT id, nome
FROM produtos_vetoriais
ORDER BY embedding <=> '[0.2,0.1,0.9]'::vector
LIMIT 5;
```

Vetor reduzido e ilustrativo; `<=>` representa distância de cosseno.

**Otimização:** comparar busca exata e índices aproximados, como HNSW e IVFFlat, com filtros reais.

**Meça:** latência, memória e **recall** — quanto do resultado exato foi recuperado.

###### Fontes: [pgvector · documentação](https://github.com/pgvector/pgvector)

<!--
NOTAS DO PROFESSOR
O exemplo pressupõe a extensão instalada e uma coluna vector(3). A dimensão foi reduzida para o slide; não sugira que representa um modelo real de linguagem. Recuperar os vizinhos exatos também não significa obter os itens semanticamente corretos: a qualidade do embedding é outra dimensão de avaliação. Busca vetorial pode ser adicionada a um banco existente, sem serviço separado.
-->

---

<!-- _class: compact -->

# Comparação: qual pergunta cada tipo favorece?

| Tipo | Pergunta característica | Exemplo |
|---|---|---|
| Relacional | Quais entidades e regras participam da operação? | PostgreSQL |
| Documental | Quais informações são acessadas juntas? | MongoDB |
| Chave-valor | Qual valor está nesta chave? | Redis |
| Wide-column | Quais registros pertencem a esta partição? | Cassandra |
| Grafo | Como estas entidades estão conectadas? | Neo4j |
| Séries temporais | Como este valor evoluiu no período? | InfluxDB |
| Colunar analítico | Qual resultado de agregar muitos registros? | ClickHouse |
| Busca textual | Quais resultados são relevantes para este texto? | Elasticsearch |
| Vetorial | Quais representações são mais próximas? | pgvector |

<!--
NOTAS DO PROFESSOR
Este é um resumo dos propósitos, não uma tabela de exclusividade. Peça um contraexemplo: PostgreSQL pode participar de busca textual, temporal e vetorial. O objetivo é reconhecer o padrão de acesso predominante. As fontes detalhadas de cada linha estão nos slides correspondentes e nas referências finais.
-->

---

<!-- _class: lead -->

# Como escolher
## Requisitos antes de produtos

**Consultas + garantias + carga + operação**

A melhor ferramenta para outro projeto pode ser a errada para este.

<!--
NOTAS DO PROFESSOR
Peça que a turma abandone temporariamente os nomes dos produtos. Uma justificativa útil descreve o que precisa acontecer e quais falhas são aceitáveis. Popularidade, familiaridade e capacidade da equipe importam, mas não substituem os requisitos.
-->

---

<!-- _class: compact -->

# Cinco perguntas antes de decidir

| Pergunta | O que precisamos conhecer |
|---|---|
| **Como os dados serão acessados?** | Consultas, filtros, ordenações e relações. |
| **Quais regras não podem ser violadas?** | Transações e garantias de leitura e escrita. |
| **Qual é a carga?** | Volume, crescimento, concorrência e picos. |
| **O que acontece em uma falha?** | Indisponibilidade, atraso e perda aceitáveis. |
| **Quem sustenta a operação?** | Equipe, manutenção, recuperação e custo. |

> Valide com uma carga representativa, não com slogans.

<!--
NOTAS DO PROFESSOR
Use a tabela como roteiro para uma decisão técnica. Peça números e cenários concretos, em vez de aceitar apenas a palavra escalável. Custo deve incluir memória, armazenamento, tráfego, cópias, monitoramento e trabalho humano. Uma prova de conceito precisa reproduzir dados e consultas relevantes, não apenas um benchmark sintético favorável.
-->

---

<!-- _class: compact -->

# Uma evolução possível para a loja

**Ponto de partida para avaliação:** PostgreSQL no núcleo transacional.

| Só acrescentar quando… | Candidato |
|---|---|
| Houver leituras repetidas que possam ser reaproveitadas. | Cache com Redis. |
| A busca exigir recursos específicos de relevância. | Elasticsearch. |
| A análise pesada justificar uma carga separada. | ClickHouse. |

Um catálogo flexível também pode usar **JSONB no PostgreSQL**.

> Cada banco adicional precisa pagar seu custo de integração e operação.

###### Fontes: [PostgreSQL · JSON](https://www.postgresql.org/docs/current/datatype-json.html)

<!--
NOTAS DO PROFESSOR
Esta é uma proposta para o cenário fictício, não uma regra universal. Não significa instalar os três componentes desde o início. Ao adicionar cópias para cache, busca ou análise, explicite qual é a fonte de referência, como as cópias serão atualizadas e como serão reconstruídas. Consulte os propósitos dos tipos apresentados, sem reabrir a comparação de marcas.
-->

---

<!-- _class: lead -->

# Teorema CAP
## E quando as réplicas deixam de se comunicar?

```text
Clientes → Réplica A    X    Réplica B ← Clientes
                  comunicação interrompida
```

As duas réplicas continuam funcionando, mas estão **isoladas entre si**.

<!--
NOTAS DO PROFESSOR
Este é um cenário hipotético de falha de comunicação, não queda das duas máquinas. Peça à turma que imagine clientes conectados dos dois lados. Uma partição de rede é diferente de particionar uma tabela ou distribuir dados por sharding. Use o exemplo de preço para evitar confundir CAP com todas as regras de estoque da aplicação.
-->

---

<!-- _class: compact -->

# CAP: três conceitos específicos

| Letra | Significado no teorema |
|---|---|
| **C — Consistência** | Linearizabilidade: operações se comportam como uma única cópia, respeitando a ordem real. |
| **A — Disponibilidade** | Requisições a nós não falhos terminam com uma resposta válida para a operação. |
| **P — Partição de rede** | A comunicação entre partes do sistema pode ser interrompida. |

**A não significa apenas uptime, resposta rápida ou devolver um erro.**

###### Fontes: [Gilbert e Lynch · Perspectives on CAP](https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf)

<!--
NOTAS DO PROFESSOR
Na linearizabilidade, cada operação aparenta ocorrer em um instante entre seu início e sua conclusão. A ordem real restringe operações que não se sobrepõem; operações concorrentes podem ter diferentes ordens válidas. A disponibilidade formal não estabelece uma meta prática de latência. P descreve o tipo de falha considerado, e não uma opção para impedir que a rede falhe.
-->

---

<!-- _class: compact -->

# Uma leitura durante a partição

Cenário hipotético: o preço inicial era **R$ 100** nas duas réplicas.

| Passo | Réplica A | Réplica B |
|---|---|---|
| A comunicação é interrompida. | Mantém R$ 100. | Mantém R$ 100. |
| Uma atualização é confirmada em A. | Passa a R$ 120. | Não recebe a alteração. |
| Depois, chega uma leitura em B. | Continua isolada. | Qual preço deve retornar? |

B não tem como confirmar se o valor local continua atualizado.

> Ela não consegue inventar a informação que não recebeu.

<!--
NOTAS DO PROFESSOR
Destaque que a atualização terminou antes do início da leitura; não são operações concorrentes. O exemplo assume que a gravação em A foi aceita. Um sistema que preserve consistência também poderia ter impedido essa gravação. A questão é mostrar por que não se pode aceitar todas as operações e manter uma única história atualizada sob essa falha.
-->

---

<!-- _class: compact -->

# Durante a partição, há uma escolha

| Preservar a consistência | Preservar a disponibilidade |
|---|---|
| Não devolver um estado que pode estar desatualizado. | Responder com os dados disponíveis localmente. |
| Impedir a conclusão de certas operações. | Aceitar que algumas respostas possam divergir. |

**CAP:** não é possível garantir simultaneamente C e A sob partições de rede.

Na loja, podemos discutir atraso em recomendações e exigir garantias diferentes para operações críticas.

###### Fontes: [Eric Brewer · CAP Twelve Years Later](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/)

<!--
NOTAS DO PROFESSOR
A restrição é sobre garantias simultâneas no modelo do teorema. O sistema não é obrigado a atingir perfeitamente uma das duas: uma implementação ruim pode falhar em ambas. As decisões podem variar por operação ou conjunto de dados. Não proponha aceitar estoque negativo simplesmente para aumentar disponibilidade; a regra de negócio exige uma análise própria.
-->

---

# CAP: o que não devemos concluir

**“Escolha quaisquer duas”** é uma simplificação ruim: a tensão entre C e A aparece diante da partição.

**“Este produto é sempre CP ou AP”** esconde configurações e garantias por operação.

**C do ACID ≠ C do CAP:** preservar invariantes não é o mesmo que linearizabilidade.

> Pergunte qual comportamento a operação oferece durante a falha.

###### Fontes: [Eric Brewer · CAP Twelve Years Later](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/) · [PostgreSQL · isolamento](https://www.postgresql.org/docs/current/transaction-iso.html)

<!--
NOTAS DO PROFESSOR
Evite discutir aqui algoritmos de consenso e provas formais. Se surgir consistência eventual, explique que convergência exige mecanismos de propagação e resolução de conflitos; ela não acontece por mágica. O CAP não resume sozinho a escolha de um banco. Reforce que as siglas simplificam discussões, mas não substituem o contrato de leitura e escrita.
-->

---

<!-- _class: lead -->

# Boas práticas e desempenho
## Otimizar é evitar trabalho desnecessário

**Medir → entender → alterar → medir novamente.**

Trocar de banco não deve ser a primeira resposta a uma consulta lenta.

<!--
NOTAS DO PROFESSOR
Mude do catálogo de tecnologias para hábitos aplicáveis à implementação. A demonstração vai manter o mesmo banco, os mesmos dados e a mesma consulta, alterando uma estrutura de acesso. Não apresente um ganho numérico antes de medir o ambiente.
-->

---

<!-- _class: compact -->

# Modele regras, não apenas campos

```sql
CREATE TABLE produtos (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku TEXT NOT NULL UNIQUE,
  nome TEXT NOT NULL,
  estoque INTEGER NOT NULL CHECK (estoque >= 0)
);
```

`NOT NULL`, `UNIQUE`, `CHECK` e chaves estrangeiras protegem regras expressáveis no banco.

**Consultar antes de inserir não substitui uma restrição de unicidade.**

###### Fontes: [PostgreSQL · constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)

<!--
NOTAS DO PROFESSOR
Mostre que duas requisições podem verificar ao mesmo tempo que um SKU ainda não existe. A restrição UNIQUE resolve a disputa na gravação; a aplicação ainda precisa tratar a falha de forma apropriada. Uma CHECK que permite apenas estoque não negativo não implementa, sozinha, todo o fluxo de reserva, pagamento e cancelamento.
-->

---

<!-- _class: compact -->

# Concorrência: verificar e alterar juntos

Exemplo PostgreSQL para reservar uma unidade:

```sql
UPDATE produtos
SET estoque = estoque - 1
WHERE id = 42 AND estoque >= 1
RETURNING id, estoque;
```

**Nenhuma linha retornada:** a reserva não foi realizada.

Para combinar reserva e pedido, use uma transação e trate falhas e repetições da operação.

> Apenas ler o estoque antes não impede uma disputa concorrente.

###### Fontes: [PostgreSQL · isolamento](https://www.postgresql.org/docs/current/transaction-iso.html) · [PostgreSQL · transações](https://www.postgresql.org/docs/current/tutorial-transactions.html)

<!--
NOTAS DO PROFESSOR
O UPDATE condicional evita separar a verificação da alteração deste registro. No PostgreSQL em Read Committed, um atualizador concorrente aguarda e o predicado é reavaliado sobre a versão atualizada. Nenhuma linha também pode significar produto inexistente. Em níveis mais fortes, podem ocorrer falhas de serialização que precisam de tratamento. Para uma compra completa, use a mesma conexão e transação, verifique o resultado e faça rollback quando necessário. Não deixe chamadas externas demoradas segurando transações abertas.
-->

---

<!-- _class: compact -->

# Segurança: dado não é comando

Trecho com `node-postgres`; `pool` já está configurado:

```javascript
const resultado = await pool.query(
  'SELECT id, nome FROM clientes WHERE email = $1',
  [email]
);
```

**Use parâmetros**, não concatenação de entradas no SQL.

A aplicação deve ter permissões mínimas; credenciais e dados sensíveis não devem aparecer no código ou nos logs.

###### Fontes: [OWASP · prevenção de SQL injection](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html) · [node-postgres · consultas parametrizadas](https://node-postgres.com/features/queries)

<!--
NOTAS DO PROFESSOR
Parâmetros separam valores da estrutura do comando. Eles não são um mecanismo para aceitar livremente nomes de tabela ou coluna enviados pelo usuário. Identificadores dinâmicos exigem uma lista permitida ou outra construção segura. Validação e autorização continuam necessárias. Não use a conta administrativa do banco na aplicação por conveniência.
-->

---

# ORM: observe o que realmente é executado

**Problema N+1:**

```text
1 consulta busca 100 pedidos.
100 consultas adicionais buscam seus clientes.
Total: 101 consultas.
```

**Possíveis correções:** projeções, joins ou carregamento em lote.

Retorne os campos necessários e limite o resultado.

> Trocar tudo para eager pode apenas mudar o problema de lugar.

###### Fontes: [Hibernate · carregamento de associações](https://docs.hibernate.org/orm/current/userguide/html_single/#fetching)

<!--
NOTAS DO PROFESSOR
O N é a quantidade de registros que dispara consultas adicionais neste exemplo. Não associe inevitavelmente N+1 a lazy, nem solução automática a eager. Inspecione o SQL e a estratégia de carregamento do ORM. O melhor formato depende do que a tela realmente precisa e da quantidade de associações envolvidas.
-->

---

<!-- _class: compact -->

# Antes de otimizar, procure evidências

| Evidência | Pergunta |
|---|---|
| Frequência e latência | Qual consulta mais pesa para o usuário? |
| Plano de execução | Como o banco encontra, combina e ordena dados? |
| Linhas e buffers | Quanto trabalho foi feito para retornar o resultado? |
| Esperas e recursos | Há disputa, conexões demais ou limite de capacidade? |

**Hipótese primeiro:** “a consulta está lendo muitos registros para devolver poucos”.

Depois, escolha uma alteração e compare novamente.

###### Fontes: [PostgreSQL · EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html)

<!--
NOTAS DO PROFESSOR
O plano ajuda a entender o trabalho interno, mas não mede sozinho toda a latência percebida na aplicação. Rede, fila de conexões e serialização da resposta também participam. Evite otimizar apenas uma execução isolada; use consultas frequentes e uma distribuição representativa dos parâmetros. O foco da demonstração será leitura e ordenação.
-->

---

<!-- _class: compact -->

# Demonstração: investigue antes de alterar

Base de estudo: **200 mil pedidos fictícios**, com 1.000 clientes.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, criado_em, total_centavos
FROM aula_db.pedidos_demo
WHERE cliente_id = 42
ORDER BY criado_em DESC, id DESC
LIMIT 20;
```

Qual caminho o banco escolheu? Precisou ordenar? Quanto trabalho realizou?

**Atenção:** `EXPLAIN ANALYZE` executa a consulta.

###### Fontes: [PostgreSQL · EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html)

<!--
NOTAS DO PROFESSOR
Prepare a base antes da apresentação. O script abaixo pode ser copiado das notas deste arquivo e executado em um banco PostgreSQL de estudo. Ele cria uma tabela demonstrativa e insere registros determinísticos. Em uma base nova, não existe ainda o índice composto da próxima etapa.

PREPARAÇÃO COMPLETA:
-- SOMENTE EM UM BANCO DE ESTUDOS DESCARTAVEL.
-- O schema aula_db separa os objetos demonstrativos.
CREATE SCHEMA IF NOT EXISTS aula_db;

CREATE TABLE IF NOT EXISTS aula_db.pedidos_demo (
  id BIGINT PRIMARY KEY,
  cliente_id BIGINT NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL,
  total_centavos BIGINT NOT NULL CHECK (total_centavos >= 0)
);

INSERT INTO aula_db.pedidos_demo
  (id, cliente_id, criado_em, total_centavos)
SELECT n,
       ((n * 37) % 1000) + 1,
       TIMESTAMPTZ '2025-01-01 00:00:00+00'
         + n * INTERVAL '1 minute',
       1000 + (n % 100000)
FROM generate_series(1, 200000) AS s(n)
ON CONFLICT (id) DO NOTHING;

ANALYZE aula_db.pedidos_demo;

Para repetir a experiência em uma base de estudos onde o índice já foi criado, remova APENAS o índice da demonstração antes da comparação:
DROP INDEX IF EXISTS aula_db.idx_pedidos_demo_cliente_data;

Não use essa instrução em uma base de produção. A chave primária continua existindo; a expressão "sem índice" refere-se à ausência do índice composto da consulta.

Execute a consulta e guarde o plano. Comandos de escrita também são efetivamente executados por EXPLAIN ANALYZE; por isso o exemplo utiliza SELECT. Não prometa um tipo de plano nem uma latência: observe o resultado do ambiente.
-->

---

# Demonstração: alinhe índice e consulta

```sql
CREATE INDEX idx_pedidos_demo_cliente_data
ON aula_db.pedidos_demo
  (cliente_id, criado_em DESC, id DESC);
```

A ordem acompanha o acesso desejado:

**cliente específico → pedidos mais recentes → desempate por id.**

Execute novamente a mesma consulta e compare o plano.

> Não mudamos de banco. Mudamos a forma de encontrar os dados.

###### Fontes: [PostgreSQL · índices compostos](https://www.postgresql.org/docs/current/indexes-multicolumn.html)

<!--
NOTAS DO PROFESSOR
O índice é criado no mesmo schema da tabela. O id torna a ordenação determinística quando há empate de data. O total_centavos não está no índice, portanto o exemplo não promete uma consulta exclusivamente coberta por ele. Este CREATE INDEX foi escolhido para uma base local; em produção, avalie bloqueios e o procedimento operacional adequado à criação de índices.
-->

---

<!-- _class: compact -->

# Compare trabalho, não um número isolado

| Antes e depois | O que observar |
|---|---|
| Acesso aos dados | Varredura sequencial ou acesso por índice? |
| Ordenação | Existe um passo separado de sort? |
| Processamento | Quantos registros e buffers participaram? |
| Resultado | As mesmas linhas e a mesma ordenação? |

Cache, estatísticas, distribuição dos dados e concorrência influenciam a medição.

**Seq Scan não é automaticamente ruim. Índice não é automaticamente bom.**

###### Fontes: [PostgreSQL · EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html) · [PostgreSQL · índices](https://www.postgresql.org/docs/current/indexes.html)

<!--
NOTAS DO PROFESSOR
Não invente valores de milissegundos nem prometa multiplicadores. Uma execução posterior pode se beneficiar de cache; repita e compare o plano, além da duração. Para tabelas pequenas ou consultas pouco seletivas, uma varredura sequencial pode ser apropriada. Lembre que manter um índice também tem custo de armazenamento e de atualização.
-->

---

<!-- _class: compact -->

# Paginação: evite descartar demais

Um `OFFSET` grande ainda exige processar as linhas ignoradas.

Alternativa ilustrativa: cursor com data e id da última linha recebida.

```sql
SELECT id, criado_em, total_centavos
FROM aula_db.pedidos_demo
WHERE cliente_id = $1
  AND (criado_em, id) < ($2::timestamptz, $3::bigint)
ORDER BY criado_em DESC, id DESC
LIMIT 20;
```

**Cuidado:** cursor precisa de ordem estável e não oferece salto livre para qualquer página.

###### Fontes: [PostgreSQL · LIMIT e OFFSET](https://www.postgresql.org/docs/current/queries-limit.html) · [PostgreSQL · índices compostos](https://www.postgresql.org/docs/current/indexes-multicolumn.html)

<!--
NOTAS DO PROFESSOR
O exemplo é uma consulta parametrizada para o driver; não deve ser colado no psql sem fornecer parâmetros ou preparar a consulta. O cursor combina a data e o id da última linha da página anterior. Os campos são NOT NULL na tabela da demonstração. Este padrão usa a mesma ordenação do índice; não garante uma fotografia imutável entre requisições se os dados mudarem. A escolha depende da experiência de navegação necessária.
-->

---

<!-- _class: compact -->

# Operação faz parte da qualidade

**Recuperação:** defina a perda de dados tolerável e o prazo para restabelecer o serviço; teste a restauração.

**Replicação não substitui backup:** uma exclusão indevida também pode chegar à réplica.

**Evolução:** versione migrações e planeje compatibilidade entre o código e o esquema.

**Observabilidade:** acompanhe falhas, consultas lentas e crescimento da base.

> Ter uma cópia não é o mesmo que comprovar a recuperação.

###### Fontes: [PostgreSQL · backup e restauração](https://www.postgresql.org/docs/current/backup.html)

<!--
NOTAS DO PROFESSOR
Proponha testar a recuperação em ambiente separado, incluindo as permissões e dependências necessárias à aplicação. Os objetivos de perda aceitável e recuperação devem ser acordados com o negócio. Como prática de implantação, prefira mudanças compatíveis e remoções posteriores ao ajuste do código. Retenção de logs e cópias deve considerar sensibilidade dos dados e necessidade operacional.
-->

---

# Checklist antes de adicionar complexidade

**A consulta está clara?** Sabemos quais dados precisamos retornar?

**O modelo e o acesso combinam?** Índices, partições e estruturas fazem sentido?

**As garantias estão protegidas?** Concorrência, validação e recuperação foram tratadas?

**Existe evidência do limite?** Medimos uma carga representativa?

> Depois disso, avalie cache, réplicas, distribuição ou outro motor.

<!--
NOTAS DO PROFESSOR
Este checklist é uma sugestão de processo de decisão. Não ensine uma ordem rígida que ignore requisitos já conhecidos: às vezes o negócio exige distribuição desde o início. A intenção é combater a adição de ferramentas como reação automática a um sintoma que ainda não foi investigado.
-->

---

<!-- _class: compact -->

# Discussão: escolha e justifique

| Cenário | O que precisa funcionar bem? |
|---|---|
| Pedido e reserva de estoque. | Alterações relacionadas sem violar a regra. |
| Catálogo com atributos diferentes. | Consultar e atualizar as estruturas do catálogo. |
| Cache do resumo dos produtos. | Recuperar por chave e reconstruir quando necessário. |
| Contas que compartilham dispositivos. | Percorrer conexões entre entidades. |
| Análise do histórico de vendas. | Agregar grandes conjuntos de registros. |

**Indique um candidato, uma vantagem e um custo da escolha.**

<!--
NOTAS DO PROFESSOR
A turma pode responder verbalmente, sem instalação nem atividade longa. Não aceite apenas o nome do banco: peça o padrão de acesso e o limite. Para cada proposta, pergunte que mudança de requisito faria o aluno reconsiderar a escolha. Reserve espaço para dúvidas antes do fechamento.
-->

---

<!-- _class: compact -->

# Respostas possíveis, não obrigatórias

| Cenário | Candidato inicial | Cuidado |
|---|---|---|
| Pedido e estoque. | Relacional. | Transação e concorrência bem implementadas. |
| Catálogo variável. | Documental ou relacional com JSON. | Limites dos documentos e consultas reais. |
| Cache de produtos. | Chave-valor. | Expiração, invalidação e reconstrução. |
| Conexões entre contas. | Grafo. | Travessias e interpretação dos resultados. |
| Grandes análises. | Colunar analítico. | Atualização da cópia e custo operacional. |

> A justificativa é mais importante do que acertar uma marca.

<!--
NOTAS DO PROFESSOR
São escolhas propostas para os cenários definidos, não uma comparação universal de produtos. Aceite alternativas tecnicamente sustentadas e retome os trade-offs apresentados. Uma mesma tecnologia pode atender vários requisitos sem exigir outro serviço imediatamente.
-->

---

<!-- _class: lead -->

# A decisão que importa

**Escolha pelo padrão de acesso.**
**Proteja as regras e entenda as falhas.**
**Otimize com evidências.**

O melhor banco atende às necessidades com uma complexidade que a equipe consegue sustentar.

<!--
NOTAS DO PROFESSOR
Retome as escolhas sugeridas pela turma no início. Peça uma única frase sobre o que mudou no raciocínio. As próximas telas são referências para consulta e não precisam ser percorridas como um novo bloco de exposição.
-->

---

<!-- _class: references -->

# Referências: fundamentos e implementação

| Tema | Documentação e leitura |
|---|---|
| Transações e concorrência | [PostgreSQL: transações](https://www.postgresql.org/docs/current/tutorial-transactions.html) · [Isolamento](https://www.postgresql.org/docs/current/transaction-iso.html) |
| Integridade e índices | [Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html) · [Índices compostos](https://www.postgresql.org/docs/current/indexes-multicolumn.html) |
| Diagnóstico e recuperação | [EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html) · [Backup](https://www.postgresql.org/docs/current/backup.html) |
| Segurança e acesso | [OWASP: SQL injection](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html) · [node-postgres](https://node-postgres.com/features/queries) |
| CAP | [Gilbert e Lynch: Perspectives on CAP](https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf) · [Eric Brewer: CAP Twelve Years Later](https://www.infoq.com/articles/cap-twelve-years-later-how-the-rules-have-changed/) |

Fontes técnicas oficiais e textos dos autores do teorema.

<!--
NOTAS DO PROFESSOR
Links clicáveis para estudo posterior. Não trate as páginas com caminho current ou latest como documentação fixada para uma versão específica de produção. Ao implementar, confira a versão utilizada no projeto.
-->

---

<!-- _class: references -->

# Referências: modelos e especializações

| Tema | Documentação |
|---|---|
| Relacional e JSON | [SQLite](https://sqlite.org/whentouse.html) · [PostgreSQL JSON](https://www.postgresql.org/docs/current/datatype-json.html) |
| Documental | [MongoDB: modelagem](https://www.mongodb.com/docs/manual/data-modeling/best-practices/) · [Diretriz ESR](https://www.mongodb.com/docs/manual/tutorial/equality-sort-range-guideline/) |
| Chave-valor | [Redis: tipos](https://redis.io/docs/latest/develop/data-types/) · [Eviction](https://redis.io/docs/latest/develop/reference/eviction/) |
| Wide-column e grafos | [Cassandra: modelagem](https://cassandra.apache.org/doc/latest/cassandra/developing/data-modeling/intro.html) · [Neo4j: conceitos](https://neo4j.com/docs/getting-started/appendix/graphdb-concepts/) |
| Temporal e analítico | [InfluxDB: modelagem](https://docs.influxdata.com/influxdb3/core/write-data/best-practices/schema-design/) · [ClickHouse: introdução](https://clickhouse.com/docs/get-started/about/intro) |
| Busca textual e vetorial | [Elasticsearch: refresh](https://www.elastic.co/docs/manage-data/data-store/near-real-time-search) · [pgvector](https://github.com/pgvector/pgvector) |

<!--
NOTAS DO PROFESSOR
Fontes adicionais de otimização estão indicadas diretamente nos slides de cada tipo. Produto, configuração, versão e carga real podem mudar a análise. Use esta lista como ponto de partida, não como ranking de ferramentas.
-->
