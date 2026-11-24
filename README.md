# Projeto LojaTudo - Data Warehouse e ETL

Este repositório contém o projeto prático da disciplina de Armazenamento, manipulação e transformação de dados. O objetivo foi pegar dados brutos (Raw Data) de uma loja fictícia e transformá-los em um Data Warehouse funcional, respondendo a perguntas estratégicas de negócio.

## 🛠️ Tecnologias Utilizadas
- **PostgreSQL:** Banco de dados relacional.
- **DBeaver:** IDE para manipulação do banco e importação de CSVs.
- **Python (Pandas, SQLAlchemy, Psycopg2):** Script de ETL (Extract, Transform, Load).
- **Draw.io:** Modelagem dos diagramas.

## 📂 Estrutura do Repositório
- `dados_brutos/`: Arquivos CSV originais (sujos).
- `modelagem/`: Diagramas OLTP e OLAP (Star Schema).
- `scripts_sql/`: Scripts de criação das tabelas, usuários e as consultas de análise.
- `etl/etl.py`: Script Python que realiza a limpeza e carga dos dados no DW.

## ⚙️ Como executar o projeto
1. Crie o banco de dados no PostgreSQL rodando os scripts da pasta `scripts_sql`.
2. Importe os arquivos CSV da pasta `dados_brutos` para o schema `staging` via DBeaver.
3. Instale as dependências Python: `pip install -r requirements.txt` (ou instale manualmente).
4. Execute o script ETL: `python etl/etl.py`.
5. Rode as consultas de análise de negócio.

## 📊 Perguntas de Negócio Respondidas
1. Faturamento total por mês e ano.
2. Top 5 produtos mais vendidos.
3. Média de gasto por cliente (agrupado por cidade), apenas clientes com >1 compra.
4. Categoria com maior crescimento no último trimestre.
5. Clientes cadastrados que nunca compraram.