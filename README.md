# Dashboard de Vendas Comerciais

Projeto de portfólio em Power BI com ETL no Power Query, modelo tabular em TMDL e relatório PBIR com três páginas.

> **Dados fictícios:** os dados foram simulados e não representam uma empresa real.

## Abrir no Power BI

1. Abra `Dashboard_Vendas.pbip` no Power BI Desktop.
2. O modelo carrega `data/raw/vendas_simuladas.csv`. Se você clonar o repositório em outro local, atualize o caminho em `Dashboard_Vendas.SemanticModel/definition/tables/vendas.tmdl` (e, se for usar o script separadamente, também em `01_power_query.pq`).
3. Se solicitado, selecione **Atualizar** para executar o ETL.
4. Para gerar um PBIX, use **Arquivo > Salvar como** no Power BI Desktop. O projeto-fonte versionável é o `.pbip`.

O arquivo `tools/gerar_pbir.ps1` recria a estrutura das páginas e visuais do relatório. Execute-o na raiz deste projeto somente se quiser regenerar essas definições; ele substitui a pasta `Dashboard_Vendas.Report/definition`.

## ETL

`01_power_query.pq` lê o CSV em UTF-8, promove e valida os cabeçalhos, tipa as colunas, remove espaços em campos de texto e verifica campos vazios, identificadores duplicados e divergências entre quantidade, preço unitário e total. A consulta retorna erro explícito se alguma validação falhar. O mesmo fluxo está embutido na partição da tabela `vendas` do modelo.

## Páginas do relatório

1. **Visão geral:** vendas, pedidos, ticket médio, média por vendedor, evolução mensal e vendas por semana.
2. **Regiões e cidades:** vendas por região e tabela por cidade com situação da região e variação dos últimos três meses.
3. **Vendedores:** ranking de vendas e matriz de vendas por vendedor e mês.

As três páginas têm segmentações de ano, região e vendedor. `Calendario[Date]` está relacionado a `vendas[data]`.

## O que os dados mostram

- **1.754 pedidos**, sem IDs repetidos, entre **01/01/2024 e 31/12/2025**.
- **R$ 3.912.196,81** em vendas simuladas.
- **4 regiões**, **16 cidades** e **5 vendedores**.
- A validação não encontrou campos vazios nem divergências entre quantidade × valor unitário e valor total.
- **Campinas** lidera as regiões com **R$ 1.554.129,31**; **Capital** vem em seguida, com **R$ 1.386.081,99**.
- A média de vendas por região é **R$ 978.049,20**. **Ribeirão Preto** (R$ 855.814,93) e **Litoral** (R$ 116.170,58) ficam abaixo dela.
- As vendas de 2025 foram **1,65% menores** que as de 2024, embora ambos os anos tenham 877 pedidos.
- **Carlos** teve o maior total entre os vendedores (**R$ 950.942,49**); esse ranking considera o período inteiro, sem segmentações.

## Estrutura

- `Dashboard_Vendas.pbip`: entrada do projeto Power BI.
- `Dashboard_Vendas.SemanticModel/`: modelo semântico em TMDL e consultas Power Query.
- `Dashboard_Vendas.SemanticModel/definition/cultures/pt-BR.tmdl`: metadados da cultura do modelo semântico.
- `Dashboard_Vendas.Report/`: relatório em formato PBIR.
- `data/raw/vendas_simuladas.csv`: arquivo-fonte simulado.
- `01_power_query.pq`: consulta ETL para referência ou uso no Editor Avançado.
- `02_medidas_dax.dax`: definições das medidas e da tabela calendário.
- `tools/gerar_pbir.ps1`: gerador das páginas e dos visuais PBIR.

## Git

Este projeto é versionado no repositório público [`thalysbastos88/vendas`](https://github.com/thalysbastos88/vendas). Para obter uma cópia, clone o repositório e abra `Dashboard_Vendas.pbip`; depois, ajuste o caminho do CSV se a pasta do projeto for diferente.
