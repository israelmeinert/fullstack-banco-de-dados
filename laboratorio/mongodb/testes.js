// Executado com mongosh; não usa o catálogo de nenhum outro projeto.
const loja = db.getSiblingDB('aula');
const produtos = loja.produtos_aula;
const checks = require('node:assert/strict');
produtos.deleteMany({});
produtos.insertMany([
  {sku: 'NOTE-001', categoria: 'informatica', preco_centavos: 450000,
   atributos: {memoria_gb: 16, armazenamento_gb: 512}},
  {sku: 'NOTE-002', categoria: 'informatica', preco_centavos: 350000,
   atributos: {memoria_gb: 8, armazenamento_gb: 256}},
  {sku: 'MOCH-42', categoria: 'acessorios', preco_centavos: 15000,
   atributos: {capacidade_litros: 20}}
]);
const consultar = () => produtos.find({categoria: 'informatica'})
  .sort({preco_centavos: 1}).limit(20);
const antes = consultar().toArray().map(p => p.sku);
produtos.createIndex({categoria: 1, preco_centavos: 1});
const depois = consultar().toArray().map(p => p.sku);
// mongosh usa contextos JavaScript distintos; compare os valores serializados.
checks.equal(JSON.stringify(antes), JSON.stringify(depois));
checks.equal(JSON.stringify(depois), JSON.stringify(['NOTE-002', 'NOTE-001']));
checks.equal(produtos.findOne({sku: 'NOTE-001'}).atributos.memoria_gb, 16);
printjson(consultar().explain('executionStats'));
print('PASS: MongoDB — documentos, filtro, ordenação e índice composto.');
