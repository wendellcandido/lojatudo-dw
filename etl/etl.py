import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
import os
import warnings

# Ignora avisos do pandas sobre inserções em massa
warnings.filterwarnings('ignore')


# Cria a conexão com o banco (DADOS DIRETOS)
DB_URL = "postgresql+pg8000://postgres:1234@localhost:5432/lojatudo"
engine = create_engine(DB_URL)

print("🔌 Conectando ao banco lojatudo com sucesso!")

# ==========================================
# 1. DIM_CLIENTE
# ==========================================
print("Processando Dim_Cliente...")
df_clientes = pd.read_sql("SELECT * FROM staging.clientes", engine)

df_clientes['nome'] = df_clientes['nome_cliente'].str.strip() # TRIM
df_clientes['email'] = df_clientes['email'].str.strip().str.lower().fillna('nao_informado@lojatudo.example') # TRIM + LOWER + Nulos
df_clientes['cidade'] = df_clientes['cidade'].str.strip().str.upper().fillna('NÃO INFORMADA') # TRIM + UPPER + Nulos
df_clientes['uf'] = df_clientes['estado'].str.strip().str.upper().fillna('NA')

# Insere no DW
df_clientes[['id_cliente', 'nome', 'email', 'cidade', 'uf']].to_sql('dim_cliente', engine, schema='dw', if_exists='append', index=False)
print(f"✅ Dim_Cliente: {len(df_clientes)} registros inseridos.")

# ==========================================
# 2. DIM_PRODUTO
# ==========================================
print("\nProcessando Dim_Produto...")
df_produtos = pd.read_sql("SELECT * FROM staging.produtos", engine)

df_produtos['nome_produto'] = df_produtos['nome_produto'].str.strip() # TRIM
df_produtos['categoria'] = df_produtos['categoria'].str.strip().str.upper() # TRIM + UPPER

df_produtos[['id_produto', 'nome_produto', 'categoria', 'preco_lista']].to_sql('dim_produto', engine, schema='dw', if_exists='append', index=False)
print(f"✅ Dim_Produto: {len(df_produtos)} registros inseridos.")

# ==========================================
# 3. DIM_TEMPO
# ==========================================
print("\nProcessando Dim_Tempo...")
df_pedidos = pd.read_sql("SELECT id_pedido, id_cliente, data_pedido, status_pedido FROM staging.pedidos", engine)

# Converte as 4 formatações de datas mistas (AAAA-MM-DD, DD/MM/AAAA, DD-MM-AAAA, AAAA/MM/DD)
df_pedidos['data_convertida'] = pd.to_datetime(df_pedidos['data_pedido'], format='mixed', dayfirst=False)

# Cria a Dim_Tempo única
df_tempo = df_pedidos[['data_convertida']].drop_duplicates().copy()
df_tempo['data_completa'] = df_tempo['data_convertida'].dt.date
df_tempo['ano'] = df_tempo['data_convertida'].dt.year
df_tempo['mes'] = df_tempo['data_convertida'].dt.month
df_tempo['trimestre'] = df_tempo['data_convertida'].dt.quarter
df_tempo['dia'] = df_tempo['data_convertida'].dt.day
df_tempo['id_tempo'] = df_tempo['data_convertida'].dt.strftime('%Y%m%d').astype(int)

df_tempo[['id_tempo', 'data_completa', 'ano', 'mes', 'trimestre', 'dia']].to_sql('dim_tempo', engine, schema='dw', if_exists='append', index=False)
print(f"✅ Dim_Tempo: {len(df_tempo)} registros inseridos.")

# ==========================================
# 4. FATO_VENDAS
# ==========================================
print("\nProcessando Fato_Vendas...")
# Traz os itens e junta com os pedidos para pegar a data
df_fato = pd.read_sql("""
    SELECT 
        i.id_item, i.id_pedido, i.id_produto, i.quantidade, i.preco_unitario,
        p.id_cliente, p.data_pedido
    FROM staging.itens_pedido i
    JOIN staging.pedidos p ON i.id_pedido = p.id_pedido
    WHERE UPPER(TRIM(p.status_pedido)) LIKE 'CONCLU%'
""", engine)

# Transformações finais
df_fato['data_convertida'] = pd.to_datetime(df_fato['data_pedido'], format='mixed', dayfirst=False)
df_fato['id_tempo'] = df_fato['data_convertida'].dt.strftime('%Y%m%d').astype(int)
df_fato['valor_total'] = df_fato['quantidade'] * df_fato['preco_unitario']

df_fato[['id_pedido', 'id_cliente', 'id_produto', 'id_tempo', 'quantidade', 'valor_total']].to_sql('fato_vendas', engine, schema='dw', if_exists='append', index=False)
print(f"✅ Fato_Vendas: {len(df_fato)} registros inseridos.")

print("\n🎉 ETL concluído com sucesso! O Data Warehouse está pronto.")