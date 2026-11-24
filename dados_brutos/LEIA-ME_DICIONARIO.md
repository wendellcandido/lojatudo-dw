# LojaTudo — Base CSV fictícia para projeto de Banco de Dados III

**Objetivo:** conjunto de dados 100% sintético, criado especificamente para a atividade prática do prof. Cláudio Neves (19/11/2026), destinada à modelagem OLTP e OLAP, implementação SQL, ETL e análise de negócio. Não são dados reais de consumidores nem de vendas.

## Arquivos de origem (RAW / staging)

| Arquivo | Registros | Uso |
|---|---:|---|
| clientes.csv | 96 | Cadastro de clientes, inclusive quem nunca comprou. |
| produtos.csv | 40 | Cadastro de produtos e categorias. |
| pedidos.csv | 610 | Cabeçalhos de pedidos com cliente, data e situação. |
| itens_pedido.csv | 1399 | Itens de cada pedido, quantidade e preço unitário efetivo. |

**Padrão:** UTF-8 com BOM; cabeçalho na primeira linha; separador **ponto e vírgula (`;`)**; valores decimais com **ponto (`.`)**; campo vazio significa valor ausente (NULL após importação adequada). Importe os IDs como números inteiros e, no schema staging, importe as datas inicialmente como TEXT/VARCHAR, para tratá-las na ETL.

## Modelo relacional sugerido pela própria base

- `clientes (id_cliente PK)` 1:N `pedidos (id_pedido PK; id_cliente FK)`
- `pedidos (id_pedido PK)` 1:N `itens_pedido (id_item PK; id_pedido FK; id_produto FK)`
- `produtos (id_produto PK)` 1:N `itens_pedido`

No modelo estrela do enunciado, é possível construir `dw.Fato_Vendas` (grão: **um produto em um pedido**), `dw.Dim_Cliente`, `dw.Dim_Produto`, `dw.Dim_Tempo`. Preserve `id_pedido` como identificador operacional na tabela fato (dimensão degenerada) para calcular **quantidade de compras distintas por cliente**. `valor_total` pode ser calculado na ETL como `quantidade * preco_unitario`, sem descontos adicionais.

## Regras de negócio para não haver ambiguidades

1. **Receita/faturamento de vendas:** considerar apenas pedidos com status **CONCLUIDO** (incluindo a variante acentuada CONCLUÍDO e espaços). `PENDENTE` e `CANCELADO` não geram receita realizada.
2. **Preço de venda:** usar `itens_pedido.preco_unitario`, e não `produtos.preco_lista`, pois este último é o preço de catálogo.
3. **Número de compras do cliente:** contar `DISTINCT id_pedido` entre pedidos concluídos, não a quantidade de linhas de item.
4. **Clientes que nunca realizaram compra:** detectar quem não possui pedido concluído; nesta base, também não possuem pedidos de outros status.
5. **Trimestre analisado:** o intervalo de vendas termina em **30/09/2026**. Portanto, o trimestre mais recente da base é **2026/T3 (julho-setembro)** e sua comparação é **2026/T2 (abril-junho)**.
6. **Categorias:** corrigir grafias antes de agrupar (ex.: `Casa & Cozinha` -> `Casa e Cozinha`; `Informatica` -> `Informática`). `UPPER` e `TRIM` sozinhos não resolvem todas as diferenças de acentuação ou digitação.
7. **Cidades:** corrigir variantes conhecidas, como `GOIANIA` e `Goiânia`, de forma explícita. Para cidade realmente vazia, preservar `NÃO INFORMADA`; não inventar município.
8. **Integridade:** toda chave estrangeira de pedido/item aponta para cadastro existente; identificadores e quantidades não contêm nulos. Os dados sujos foram concentrados em textos, datas e campos não críticos para permitir uma ETL didática.

## Dicionário de dados

### clientes.csv

| Coluna | Tipo recomendado | Descrição |
|---|---|---|
| `id_cliente` | inteiro | Identificador único do cliente, PK (sem valores ausentes). |
| `nome_cliente` | texto | Nome fictício; alguns valores com espaços laterais. |
| `email` | texto | E-mail fictício em domínio reservado .example; alguns em branco/maiúsculas. |
| `cidade` | texto | Cidade; inclui variações de capitalização, acentuação e 1 valor vazio. |
| `estado` | texto | Sigla da UF; alguns valores minúsculos e vazios. |
| `telefone` | texto | Telefone estritamente fictício; há campos vazios. |
| `data_cadastro` | texto na staging -> DATE no DW | Data em formatos diferentes e alguns vazios. |

### produtos.csv

| Coluna | Tipo recomendado | Descrição |
|---|---|---|
| `id_produto` | inteiro | Identificador único do produto, PK. |
| `nome_produto` | texto | Descrição do produto; alguns valores com espaços. |
| `categoria` | texto | Categoria; contém erros de digitação controlados e variação de grafia. |
| `preco_lista` | decimal(10,2) | Preço de catálogo em BRL, com ponto decimal. |
| `ativo` | texto | Indicador textual de produto ativo (SIM/sim). |

### pedidos.csv

| Coluna | Tipo recomendado | Descrição |
|---|---|---|
| `id_pedido` | inteiro | Identificador único do pedido, PK. |
| `id_cliente` | inteiro | FK lógica para clientes.id_cliente. |
| `data_pedido` | texto na staging -> DATE no DW | Data da compra em 4 formatos reconhecíveis. |
| `status_pedido` | texto | Concluido, Cancelado ou Pendente, com variações de grafia. |
| `canal_venda` | texto | Site, Aplicativo, WhatsApp ou Loja física; variações de caixa/espaços. |

### itens_pedido.csv

| Coluna | Tipo recomendado | Descrição |
|---|---|---|
| `id_item` | inteiro | Identificador único do item, PK. |
| `id_pedido` | inteiro | FK lógica para pedidos.id_pedido. |
| `id_produto` | inteiro | FK lógica para produtos.id_produto. |
| `quantidade` | inteiro | Unidades vendidas, sempre positivas. |
| `preco_unitario` | decimal(10,2) | Preço efetivo praticado por item em BRL, ponto decimal. |

## Problemas propositais para exercitar ETL

- Espaços extras em nomes, categorias, canais e cidades: `TRIM`.
- Maiúsculas/minúsculas inconsistentes em cidade, canal, status e e-mail: `UPPER`/`LOWER`.
- Grafias alternativas e ausência de acentos nas categorias e cidades: `CASE` + mapeamento explícito.
- Datas em `AAAA-MM-DD`, `DD/MM/AAAA`, `DD-MM-AAAA` e `AAAA/MM/DD`: conversão por padrão conhecido.
- Campos vazios em e-mail, telefone, estado, cidade e data de cadastro: `NULLIF` / tratamento de nulos.
- Status de venda inconsistente: normalizar antes de montar `Fato_Vendas` e filtrar vendas concluídas.

Os problemas são intencionais: **não corrija os arquivos de origem**. Importe os brutos para `staging` e realize as transformações via SQL na Fase 3.

## Cobertura dos 5 requisitos da Fase 4

| Pergunta | Dados que permitem responder |
|---|---|
| 1. Faturamento por mês/ano | Data em pedidos + quantidade/preço nos itens + status |
| 2. Cinco produtos mais vendidos e receita | id_produto, quantidade e preco_unitario nos itens |
| 3. Gasto médio por cliente/cidade, apenas clientes com mais de 1 compra | cliente -> pedido -> itens; contar pedidos DISTINCT e agrupar por cidade padronizada |
| 4. Crescimento de categoria entre trimestres | categoria em produtos + data/status em pedidos + valor nos itens |
| 5. Clientes cadastrados sem compras | clientes (incluídos 24 sem pedido) + LEFT JOIN com pedidos concluídos |

## Cuidados na modelagem

O enunciado pede os schemas `staging` e `dw`, e dois usuários (`user_etl` com escrita e `user_analista` apenas leitura). Na Fase 2, as permissões devem ser restritas a objetos apropriados, especialmente `dw`. O esquema operacional OLTP é um **diagrama de referência**; as tabelas operacionais são representadas nos arquivos CSV. Você pode construir o modelo dimensional dentro de `dw` conforme o professor.

**Observação sobre o PDF:** o texto do professor anuncia cinco fases, porém o material fornecido descreve apenas as Fases 1–4. Não foi criada uma Fase 5 fictícia aqui.
