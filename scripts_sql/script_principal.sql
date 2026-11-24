-- =====================================================================
-- PROJETO LOJATUDO - DATA WAREHOUSE
-- Aluno: Wendell Candido
-- =====================================================================

-- =====================================================================
-- FASE 2: IMPLEMENTAÇÃO E SEGURANÇA (DDL)
-- =====================================================================

-- 1. CRIAR OS SCHEMAS
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

-- 2. CRIAR AS TABELAS DO STAGING (Dados Brutos)
CREATE TABLE staging.clientes (
    id_cliente INT, nome_cliente VARCHAR(150), email VARCHAR(150), 
    cidade VARCHAR(100), estado VARCHAR(10), telefone VARCHAR(30), data_cadastro VARCHAR(30)
);
CREATE TABLE staging.produtos (
    id_produto INT, nome_produto VARCHAR(150), categoria VARCHAR(100), 
    preco_lista NUMERIC(10,2), ativo VARCHAR(10)
);
CREATE TABLE staging.pedidos (
    id_pedido INT, id_cliente INT, data_pedido VARCHAR(30), 
    status_pedido VARCHAR(50), canal_venda VARCHAR(50)
);
CREATE TABLE staging.itens_pedido (
    id_item INT, id_pedido INT, id_produto INT, quantidade INT, preco_unitario NUMERIC(10,2)
);

-- 3. CRIAR AS TABELAS DO DW (Modelo Estrela)
CREATE TABLE dw.dim_cliente (
    id_cliente INT PRIMARY KEY NOT NULL, nome VARCHAR(150) NOT NULL, 
    email VARCHAR(150), cidade VARCHAR(100) NOT NULL, uf CHAR(2)
);
CREATE TABLE dw.dim_produto (
    id_produto INT PRIMARY KEY NOT NULL, nome_produto VARCHAR(150) NOT NULL, 
    categoria VARCHAR(100) NOT NULL, preco_lista NUMERIC(10,2) NOT NULL
);
CREATE TABLE dw.dim_tempo (
    id_tempo INT PRIMARY KEY NOT NULL, data_completa DATE NOT NULL, 
    ano INT NOT NULL, mes INT NOT NULL, trimestre INT NOT NULL, dia INT NOT NULL
);
CREATE TABLE dw.fato_vendas (
    id_fato SERIAL PRIMARY KEY NOT NULL, id_pedido INT NOT NULL, id_cliente INT NOT NULL,
    id_produto INT NOT NULL, id_tempo INT NOT NULL, quantidade INT NOT NULL, valor_total NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_cliente FOREIGN KEY (id_cliente) REFERENCES dw.dim_cliente(id_cliente),
    CONSTRAINT fk_produto FOREIGN KEY (id_produto) REFERENCES dw.dim_produto(id_produto),
    CONSTRAINT fk_tempo FOREIGN KEY (id_tempo) REFERENCES dw.dim_tempo(id_tempo)
);

-- 4. CRIAR OS USUÁRIOS E PERMISSÕES (Segurança)
CREATE USER user_etl WITH PASSWORD 'senha_etl_123';
CREATE USER user_analista WITH PASSWORD 'senha_analista_456';

GRANT USAGE ON SCHEMA staging TO user_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA staging TO user_etl;
GRANT USAGE ON SCHEMA dw TO user_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dw TO user_etl;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA dw TO user_etl;
GRANT USAGE ON SCHEMA dw TO user_analista;
GRANT SELECT ON ALL TABLES IN SCHEMA dw TO user_analista;

-- =====================================================================
-- FASE 4: ANÁLISE DE NEGÓCIO (As 5 Perguntas)
-- =====================================================================

-- 1. Faturamento total por mês e ano
SELECT t.ano, t.mes, SUM(f.valor_total) AS faturamento_total
FROM dw.fato_vendas f
JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
GROUP BY t.ano, t.mes
ORDER BY t.ano, t.mes;

-- 2. Top 5 produtos mais vendidos e valor gerado
SELECT p.nome_produto, SUM(f.quantidade) AS total_quantidade_vendida, SUM(f.valor_total) AS valor_total_gerado
FROM dw.fato_vendas f
JOIN dw.dim_produto p ON f.id_produto = p.id_produto
GROUP BY p.nome_produto
ORDER BY total_quantidade_vendida DESC
LIMIT 5;

-- 3. Média de gasto por cliente agrupado por cidade (apenas clientes com >1 compra)
SELECT c.cidade, ROUND(AVG(f.valor_total), 2) AS media_gasto_por_cliente
FROM dw.fato_vendas f
JOIN dw.dim_cliente c ON f.id_cliente = c.id_cliente
WHERE f.id_cliente IN (
    SELECT id_cliente FROM dw.fato_vendas GROUP BY id_cliente HAVING COUNT(DISTINCT id_pedido) > 1
)
GROUP BY c.cidade
ORDER BY media_gasto_por_cliente DESC;

-- 4. Categoria com maior crescimento no último trimestre (T3 vs T2 de 2026)
WITH FaturamentoTrimestral AS (
    SELECT p.categoria, t.ano, t.trimestre, SUM(f.valor_total) AS total_vendas
    FROM dw.fato_vendas f
    JOIN dw.dim_produto p ON f.id_produto = p.id_produto
    JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
    WHERE (t.ano = 2026 AND t.trimestre IN (2, 3))
    GROUP BY p.categoria, t.ano, t.trimestre
),
Comparacao AS (
    SELECT t3.categoria, t2.total_vendas AS vendas_t2, t3.total_vendas AS vendas_t3,
        (t3.total_vendas - t2.total_vendas) AS crescimento_absoluto,
        ROUND(((t3.total_vendas - t2.total_vendas) / t2.total_vendas) * 100, 2) AS crescimento_percentual
    FROM FaturamentoTrimestral t3
    JOIN FaturamentoTrimestral t2 ON t3.categoria = t2.categoria AND t2.ano = 2026 AND t2.trimestre = 2
    WHERE t3.ano = 2026 AND t3.trimestre = 3
)
SELECT categoria, vendas_t2, vendas_t3, crescimento_absoluto, crescimento_percentual
FROM Comparacao
ORDER BY crescimento_percentual DESC;

-- 5. Clientes cadastrados que nunca realizaram compras
SELECT c.nome, c.email
FROM dw.dim_cliente c
LEFT JOIN dw.fato_vendas f ON c.id_cliente = f.id_cliente
WHERE f.id_cliente IS NULL;