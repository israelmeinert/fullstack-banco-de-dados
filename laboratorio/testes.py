"""Testes de integração e relatórios do laboratório, sem dados externos."""

import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import sqlite3
from threading import Barrier
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import psycopg


RESULTADOS = Path('/resultados')
RESULTADOS.mkdir(parents=True, exist_ok=True)


def salvar(nome, valor):
    (RESULTADOS / nome).write_text(
        json.dumps(valor, indent=2, ensure_ascii=False, default=str) + '\n',
        encoding='utf-8',
    )


def verificar(condicao, mensagem):
    if not condicao:
        raise AssertionError(mensagem)
    print('PASS:', mensagem)


def conectar():
    return psycopg.connect(autocommit=True, options='-c search_path=aula_db,public')


def plano(conexao, consulta, parametros=()):
    return conexao.execute(
        'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' + consulta, parametros
    ).fetchone()[0][0]


def resumo_plano(dados):
    def tipos(no):
        return [no['Node Type']] + [t for filho in no.get('Plans', []) for t in tipos(filho)]
    raiz = dados['Plan']
    return {
        'operacoes': tipos(raiz),
        'tempo_execucao_ms': dados['Execution Time'],
        'buffers_hit': raiz.get('Shared Hit Blocks', 0),
        'buffers_read': raiz.get('Shared Read Blocks', 0),
        'linhas_retornadas': raiz['Actual Rows'],
    }


def postgres():
    consulta = '''SELECT id, criado_em, total_centavos
                  FROM aula_db.pedidos_demo WHERE cliente_id = %s
                  ORDER BY criado_em DESC, id DESC LIMIT 20'''
    with conectar() as c:
        c.execute(Path('/lab/postgres/01-preparar.sql').read_text(encoding='utf-8'))
        verificar(c.execute('SELECT count(*), count(DISTINCT cliente_id) FROM pedidos_demo').fetchone()
                  == (200000, 1000), '200 mil pedidos distribuídos entre mil clientes')
        c.execute('DROP INDEX IF EXISTS aula_db.idx_pedidos_demo_cliente_data')
        antes = c.execute(consulta, (42,)).fetchall()
        plano_antes = plano(c, consulta, (42,))
        c.execute('''CREATE INDEX idx_pedidos_demo_cliente_data
                     ON aula_db.pedidos_demo (cliente_id, criado_em DESC, id DESC)''')
        c.execute('ANALYZE aula_db.pedidos_demo')
        depois = c.execute(consulta, (42,)).fetchall()
        plano_depois = plano(c, consulta, (42,))
        verificar(antes == depois and len(depois) == 20,
                  'índice preserva as 20 linhas e sua ordenação')
        salvar('postgres-plano-antes.json', plano_antes)
        salvar('postgres-plano-depois.json', plano_depois)
        comparacao = {'antes': resumo_plano(plano_antes), 'depois': resumo_plano(plano_depois)}
        print(json.dumps(comparacao, ensure_ascii=False, indent=2))
        salvar('postgres-comparacao.json', comparacao)

        cursor_data, cursor_id = depois[-1][1], depois[-1][0]
        pagina2 = c.execute('''SELECT id, criado_em, total_centavos FROM pedidos_demo
                              WHERE cliente_id = %s AND (criado_em, id) < (%s, %s)
                              ORDER BY criado_em DESC, id DESC LIMIT 20''',
                            (42, cursor_data, cursor_id)).fetchall()
        referencia = c.execute(consulta.replace('LIMIT 20', 'LIMIT 20 OFFSET 20'), (42,)).fetchall()
        verificar(pagina2 == referencia and len(pagina2) == 20
                  and not ({r[0] for r in depois} & {r[0] for r in pagina2}),
                  'paginação por cursor preserva a ordem sem repetir pedidos')

        seguro = 'SELECT id, nome FROM clientes WHERE email = %s'
        verificar(c.execute(seguro, ('cliente42@exemplo.test',)).fetchone() == (42, 'Cliente 42'),
                  'consulta parametrizada encontra o cliente esperado')
        verificar(c.execute(seguro, ("' OR 1=1 --",)).fetchall() == [],
                  'entrada com SQL é tratada como valor na consulta parametrizada')
        verificar(len(c.execute('''SELECT p.id, p.criado_em, c.nome FROM pedidos_demo p
                                  JOIN clientes c ON c.id = p.cliente_id
                                  WHERE p.cliente_id = 42
                                  ORDER BY p.criado_em DESC, p.id DESC LIMIT 20''').fetchall()) == 20,
                  'JOIN recupera os pedidos junto do cliente')

        restricoes = [
            ("INSERT INTO produtos (sku,nome,estoque) VALUES ('MOCH-42','Duplicado',1)",
             psycopg.errors.UniqueViolation, 'SKU duplicado é rejeitado por UNIQUE'),
            ('UPDATE produtos SET estoque = -1 WHERE id = 42',
             psycopg.errors.CheckViolation, 'estoque negativo é rejeitado por CHECK'),
            ('UPDATE produtos SET nome = NULL WHERE id = 42',
             psycopg.errors.NotNullViolation, 'nome ausente é rejeitado por NOT NULL'),
            ('INSERT INTO reservas (produto_id,quantidade) VALUES (-1,1)',
             psycopg.errors.ForeignKeyViolation, 'reserva sem produto é rejeitada pela chave estrangeira'),
        ]
        for sql, erro, mensagem in restricoes:
            try:
                with c.transaction():
                    c.execute(sql)
            except erro:
                verificar(True, mensagem)
            else:
                raise AssertionError(mensagem)

        c.execute('DELETE FROM reservas WHERE produto_id = 42')
        c.execute('UPDATE produtos SET estoque = 1 WHERE id = 42')
        try:
            with c.transaction():
                c.execute('UPDATE produtos SET estoque = estoque - 1 WHERE id = 42 AND estoque >= 1')
                c.execute('INSERT INTO reservas (produto_id,quantidade) VALUES (42,1)')
                raise RuntimeError('falha simulada antes do commit')
        except RuntimeError:
            pass
        verificar(c.execute('SELECT estoque FROM produtos WHERE id = 42').fetchone()[0] == 1
                  and c.execute('SELECT count(*) FROM reservas WHERE produto_id = 42').fetchone()[0] == 0,
                  'rollback desfaz estoque e reserva juntos')

    barreira = Barrier(2)

    def reservar(_):
        # Duas conexões e transações independentes disputam a mesma unidade.
        with psycopg.connect(options='-c search_path=aula_db,public') as c:
            c.execute('SET TRANSACTION ISOLATION LEVEL READ COMMITTED')
            barreira.wait(timeout=15)
            linha = c.execute('''UPDATE produtos SET estoque = estoque - 1
                                 WHERE id = 42 AND estoque >= 1 RETURNING id, estoque''').fetchone()
            if linha:
                c.execute('SELECT pg_sleep(0.2)')
                c.execute('INSERT INTO reservas (produto_id,quantidade) VALUES (42,1)')
            return linha

    with ThreadPoolExecutor(max_workers=2) as executor:
        reservas = list(executor.map(reservar, range(2)))
    with conectar() as c:
        verificar(sum(r is not None for r in reservas) == 1
                  and c.execute('SELECT estoque FROM produtos WHERE id = 42').fetchone()[0] == 0
                  and c.execute('SELECT count(*) FROM reservas WHERE produto_id = 42').fetchone()[0] == 1,
                  'duas compras concorrentes geram uma reserva e estoque zero')
    return {'comparacao': comparacao, 'reservas_concorrentes': reservas}


def vetorial():
    with conectar() as c:
        c.execute('CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public')
        c.execute('CREATE SCHEMA IF NOT EXISTS aula_db')
        c.execute('''CREATE TABLE IF NOT EXISTS aula_db.produtos_vetoriais (
                     id bigint PRIMARY KEY, nome text NOT NULL, embedding vector(3) NOT NULL)''')
        c.execute('TRUNCATE aula_db.produtos_vetoriais')
        c.execute('DROP INDEX IF EXISTS aula_db.idx_produtos_embedding_hnsw')
        # Vetores artificiais de dimensão 3; não são embeddings de linguagem.
        linhas = [(i, f'Produto {i}',
                   f'[{(i * 17 % 101 + 1) / 101},{(i * 31 % 103 + 1) / 103},{(i * 47 % 107 + 1) / 107}]')
                  for i in range(1, 2001)]
        with c.cursor() as cur:
            cur.executemany('INSERT INTO produtos_vetoriais VALUES (%s, %s, %s::vector)', linhas)
        c.execute('ANALYZE aula_db.produtos_vetoriais')
        consulta = '''SELECT id, nome FROM aula_db.produtos_vetoriais
                      ORDER BY embedding <=> %s::vector LIMIT 5'''
        alvo = '[0.2,0.1,0.9]'
        exato = c.execute(consulta, (alvo,)).fetchall()
        plano_exato = plano(c, consulta, (alvo,))
        c.execute('''CREATE INDEX idx_produtos_embedding_hnsw ON produtos_vetoriais
                     USING hnsw (embedding vector_cosine_ops)''')
        c.execute('SET hnsw.ef_search = 100')
        aproximado = c.execute(consulta, (alvo,)).fetchall()
        plano_aproximado = plano(c, consulta, (alvo,))
        recall = len({r[0] for r in exato} & {r[0] for r in aproximado}) / 5
        verificar(len(exato) == len(aproximado) == 5, 'buscas vetoriais retornam cinco produtos')
        dados = {'recall_at_5': recall, 'exato': exato, 'aproximado': aproximado,
                 'plano_exato': plano_exato, 'plano_aproximado': plano_aproximado,
                 'observacao': 'Recall medido nesta consulta; não é garantia nem avaliação semântica.'}
        salvar('vetorial-comparacao.json', dados)
        print(f'Recall@5 observado: {recall:.0%}; confira o plano para saber se HNSW foi usado.')
        return {'recall_at_5': recall}


def sqlite():
    # O módulo sqlite3 é embarcado no processo; nenhum servidor adicional.
    with sqlite3.connect(':memory:') as c:
        c.execute('CREATE TABLE produtos (id INTEGER PRIMARY KEY, estoque INTEGER NOT NULL CHECK (estoque >= 0))')
        c.execute('INSERT INTO produtos VALUES (42, 1)')
        c.commit()
        c.execute('UPDATE produtos SET estoque = 0 WHERE id = 42')
        c.rollback()
        verificar(c.execute('SELECT estoque FROM produtos WHERE id = 42').fetchone()[0] == 1,
                  'SQLite embarcado faz rollback sem serviço separado')
        try:
            c.execute('UPDATE produtos SET estoque = -1 WHERE id = 42')
        except sqlite3.IntegrityError:
            verificar(True, 'SQLite rejeita estoque negativo')
        else:
            raise AssertionError('SQLite deveria rejeitar estoque negativo')
    return {'rollback': True, 'check': True}


def http(url, method='GET', dados=None, texto=None, ignorar=(), content_type='text/plain'):
    headers = {}
    corpo = None
    if dados is not None:
        corpo = json.dumps(dados).encode()
        headers['Content-Type'] = 'application/json'
    if texto is not None:
        corpo = texto.encode()
        headers['Content-Type'] = content_type
    try:
        with urlopen(Request(url, data=corpo, headers=headers, method=method), timeout=30) as resposta:
            conteudo = resposta.read().decode()
            return json.loads(conteudo) if conteudo else None
    except HTTPError as erro:
        if erro.code in ignorar:
            return None
        raise RuntimeError(f'{method} {url}: HTTP {erro.code}: {erro.read().decode()}') from erro


def influxdb():
    base = 'http://influxdb:8181'
    # Timestamp em nanossegundos; conjunto pequeno e determinístico.
    medidas = '\n'.join([
        'temperaturas,equipamento=camara-01 temperatura=3.2 1735725600000000000',
        'temperaturas,equipamento=camara-01 temperatura=3.4 1735725660000000000',
        'temperaturas,equipamento=camara-01 temperatura=3.3 1735725720000000000',
        'temperaturas,equipamento=camara-02 temperatura=8.0 1735725600000000000',
    ])
    http(base + '/api/v3/write_lp?db=aula&precision=nanosecond', 'POST', texto=medidas)
    consulta = '''SELECT equipamento, AVG(temperatura) AS media, COUNT(*) AS quantidade
                  FROM temperaturas WHERE equipamento = 'camara-01'
                  AND time >= '2025-01-01T10:00:00Z' AND time < '2025-01-01T10:03:00Z'
                  GROUP BY equipamento'''
    resultado = http(base + '/api/v3/query_sql?' + urlencode({'db': 'aula', 'q': consulta, 'format': 'json'}))
    verificar(len(resultado) == 1 and resultado[0]['quantidade'] == 3
              and math.isclose(resultado[0]['media'], 3.3, abs_tol=1e-8),
              'InfluxDB 3 filtra série e janela temporal e calcula média 3,3 °C')
    salvar('influxdb-consulta.json', resultado)
    return resultado


def elasticsearch():
    base = 'http://elasticsearch:9200'
    indice = base + '/aula-produtos'
    http(indice, 'DELETE', ignorar=(404,))
    http(indice, 'PUT', dados={'mappings': {'properties': {
        'nome': {'type': 'text', 'analyzer': 'portuguese'},
        'categoria': {'type': 'keyword'},
    }}})
    documentos = [(42, 'Mochila para notebook', 'acessorios'),
                  (43, 'Notebook de 16 GB', 'informatica'),
                  (44, 'Camiseta de algodão', 'roupas')]
    lote = '\n'.join(linha for id_, nome, categoria in documentos for linha in (
        json.dumps({'index': {'_id': str(id_)}}),
        json.dumps({'nome': nome, 'categoria': categoria}, ensure_ascii=False),
    )) + '\n'
    resultado_lote = http(indice + '/_bulk?refresh=wait_for', 'POST', texto=lote,
                          content_type='application/x-ndjson')
    verificar(not resultado_lote['errors'], 'Elasticsearch indexa o catálogo em lote')
    resultado = http(indice + '/_search', 'POST', dados={'query': {'bool': {
        'must': [{'match': {'nome': 'mochila notebook'}}],
        'filter': [{'term': {'categoria': 'acessorios'}}],
    }}})
    verificar([r['_id'] for r in resultado['hits']['hits']] == ['42'],
              'busca textual com filtro keyword encontra a mochila')
    salvar('elasticsearch-busca.json', resultado)
    return {'ids': [r['_id'] for r in resultado['hits']['hits']]}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('tecnologia', choices=['postgres', 'vetorial', 'sqlite', 'influxdb', 'elasticsearch'])
    grupo = parser.parse_args().tecnologia
    relatorio = {'tecnologia': grupo, 'executado_em': datetime.now(timezone.utc).isoformat()}
    try:
        relatorio['resultado'] = globals()[grupo]()
        relatorio['status'] = 'passou'
    except Exception as erro:
        relatorio.update(status='falhou', erro=str(erro))
        raise
    finally:
        salvar(f'{grupo}-resultado.json', relatorio)
