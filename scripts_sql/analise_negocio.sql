# Pergunta 1: Qual foi o faturamento total da loja por mês e ano?
SELECT 
    t.ano, 
    t.mes, 
    SUM(f.valor_total) AS faturamento_total
FROM dw.fato_vendas f
JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
GROUP BY t.ano, t.mes
ORDER BY t.ano, t.mes;

# 2. Quais são os 5 produtos mais vendidos em quantidade e qual o valor total gerado por eles?

SELECT 
    p.nome_produto,
    SUM(f.quantidade) AS total_quantidade_vendida,
    SUM(f.valor_total) AS valor_total_gerado
FROM dw.fato_vendas f
JOIN dw.dim_produto p ON f.id_produto = p.id_produto
GROUP BY p.nome_produto
ORDER BY total_quantidade_vendida DESC
LIMIT 5;
 
# 3. Qual é a média de gasto por cliente, agrupado por cidade? (Apenas clientes com mais de 1 compra). 

SELECT 
    c.cidade,
    ROUND(AVG(f.valor_total), 2) AS media_gasto_por_cliente
FROM dw.fato_vendas f
JOIN dw.dim_cliente c ON f.id_cliente = c.id_cliente
WHERE f.id_cliente IN (
    -- Subquery: Busca apenas clientes com mais de 1 pedido distinto
    SELECT id_cliente 
    FROM dw.fato_vendas 
    GROUP BY id_cliente 
    HAVING COUNT(DISTINCT id_pedido) > 1
)
GROUP BY c.cidade
ORDER BY media_gasto_por_cliente DESC;

# 4. Qual categoria de produto teve o maior crescimento de vendas no último trimestre em relação ao anterior?

WITH FaturamentoTrimestral AS (
    SELECT 
        p.categoria,
        t.ano,
        t.trimestre,
        SUM(f.valor_total) AS total_vendas
    FROM dw.fato_vendas f
    JOIN dw.dim_produto p ON f.id_produto = p.id_produto
    JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
    -- Filtra apenas os trimestres que queremos comparar (T2 e T3 de 2026)
    WHERE (t.ano = 2026 AND t.trimestre IN (2, 3))
    GROUP BY p.categoria, t.ano, t.trimestre
),
Comparacao AS (
    SELECT 
        t3.categoria,
        t2.total_vendas AS vendas_t2,
        t3.total_vendas AS vendas_t3,
        (t3.total_vendas - t2.total_vendas) AS crescimento_absoluto,
        ROUND(((t3.total_vendas - t2.total_vendas) / t2.total_vendas) * 100, 2) AS crescimento_percentual
    FROM FaturamentoTrimestral t3
    JOIN FaturamentoTrimestral t2 
      ON t3.categoria = t2.categoria 
     AND t2.ano = 2026 AND t2.trimestre = 2
    WHERE t3.ano = 2026 AND t3.trimestre = 3
)
SELECT 
    categoria,
    vendas_t2,
    vendas_t3,
    crescimento_absoluto,
    crescimento_percentual
FROM Comparacao
ORDER BY crescimento_percentual DESC;

5. Liste o nome e e-mail de clientes que estão cadastrados, mas nunca realizaram uma compra.

WITH FaturamentoTrimestral AS (
    SELECT 
        p.categoria,
        t.ano,
        t.trimestre,
        SUM(f.valor_total) AS total_vendas
    FROM dw.fato_vendas f
    JOIN dw.dim_produto p ON f.id_produto = p.id_produto
    JOIN dw.dim_tempo t ON f.id_tempo = t.id_tempo
    -- Filtra apenas os trimestres que queremos comparar (T2 e T3 de 2026)
    WHERE (t.ano = 2026 AND t.trimestre IN (2, 3))
    GROUP BY p.categoria, t.ano, t.trimestre
),
Comparacao AS (
    SELECT 
        t3.categoria,
        t2.total_vendas AS vendas_t2,
        t3.total_vendas AS vendas_t3,
        (t3.total_vendas - t2.total_vendas) AS crescimento_absoluto,
        ROUND(((t3.total_vendas - t2.total_vendas) / t2.total_vendas) * 100, 2) AS crescimento_percentual
    FROM FaturamentoTrimestral t3
    JOIN FaturamentoTrimestral t2 
      ON t3.categoria = t2.categoria 
     AND t2.ano = 2026 AND t2.trimestre = 2
    WHERE t3.ano = 2026 AND t3.trimestre = 3
)
SELECT 
    categoria,
    vendas_t2,
    vendas_t3,
    crescimento_absoluto,
    crescimento_percentual
FROM Comparacao
ORDER BY crescimento_percentual DESC;