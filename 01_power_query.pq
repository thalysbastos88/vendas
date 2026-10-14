let
    CaminhoArquivo = "C:\Users\User\Downloads\dashboard_vendas_powerbi\data\raw\vendas_simuladas.csv",
    Arquivo = Csv.Document(
        File.Contents(CaminhoArquivo),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Cabecalhos = Table.PromoteHeaders(Arquivo, [PromoteAllScalars = true]),
    ColunasEsperadas = {
        "id_pedido", "data", "vendedor", "regiao", "cidade",
        "produto", "quantidade", "valor_unitario", "valor_total"
    },
    ColunasAusentes = List.Difference(ColunasEsperadas, Table.ColumnNames(Cabecalhos)),
    ValidarCabecalhos =
        if not List.IsEmpty(ColunasAusentes) then
            error Error.Record(
                "ETL.Cabecalhos",
                "O CSV não contém todas as colunas obrigatórias.",
                [ColunasAusentes = ColunasAusentes]
            )
        else
            Table.SelectColumns(Cabecalhos, ColunasEsperadas),
    Tipos = Table.TransformColumnTypes(
        ValidarCabecalhos,
        {
            {"id_pedido", type text},
            {"data", type date},
            {"vendedor", type text},
            {"regiao", type text},
            {"cidade", type text},
            {"produto", type text},
            {"quantidade", Int64.Type},
            {"valor_unitario", Currency.Type},
            {"valor_total", Currency.Type}
        },
        "en-US"
    ),
    TextosSemEspacos = Table.TransformColumns(
        Tipos,
        {
            {"id_pedido", Text.Trim, type text},
            {"vendedor", Text.Trim, type text},
            {"regiao", Text.Trim, type text},
            {"cidade", Text.Trim, type text},
            {"produto", Text.Trim, type text}
        }
    ),
    LinhasVazias = Table.SelectRows(
        TextosSemEspacos,
        each List.AnyTrue(
            List.Transform(
                Record.FieldValues(_),
                (valor) => valor = null or (valor is text and Text.Trim(valor) = "")
            )
        )
    ),
    IDsDuplicados = Table.SelectRows(
        Table.Group(TextosSemEspacos, {"id_pedido"}, {{"Quantidade", each Table.RowCount(_), Int64.Type}}),
        each [Quantidade] > 1
    ),
    TotaisInvalidos = Table.SelectRows(
        TextosSemEspacos,
        each Number.Round([quantidade] * [valor_unitario], 2) <> Number.Round([valor_total], 2)
    ),
    ValidarDados =
        if Table.RowCount(LinhasVazias) > 0 then
            error Error.Record("ETL.CamposVazios", "O CSV contém campos vazios.", [Quantidade = Table.RowCount(LinhasVazias)])
        else if Table.RowCount(IDsDuplicados) > 0 then
            error Error.Record("ETL.IDDuplicado", "O CSV contém IDs de pedido repetidos.", [Quantidade = Table.RowCount(IDsDuplicados)])
        else if Table.RowCount(TotaisInvalidos) > 0 then
            error Error.Record("ETL.TotalInvalido", "Há linhas em que quantidade × valor unitário difere do valor total.", [Quantidade = Table.RowCount(TotaisInvalidos)])
        else
            TextosSemEspacos
in
    ValidarDados
