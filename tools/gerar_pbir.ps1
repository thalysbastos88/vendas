$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$reportRoot = Join-Path $projectRoot "Dashboard_Vendas.Report"
$definitionRoot = Join-Path $reportRoot "definition"
$pagesRoot = Join-Path $definitionRoot "pages"

if (Test-Path -LiteralPath $definitionRoot) {
    Remove-Item -LiteralPath $definitionRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $pagesRoot -Force | Out-Null

function New-ColumnField {
    param([string]$Entity, [string]$Property)
    return @{ Column = @{ Expression = @{ SourceRef = @{ Entity = $Entity } }; Property = $Property } }
}

function New-MeasureField {
    param([string]$Entity, [string]$Property)
    return @{ Measure = @{ Expression = @{ SourceRef = @{ Entity = $Entity } }; Property = $Property } }
}

function New-Projection {
    param([hashtable]$Field, [string]$QueryRef)
    return @{ field = $Field; queryRef = $QueryRef; active = $true }
}

function New-Visual {
    param(
        [string]$PagePath,
        [string]$Name,
        [string]$Type,
        [string]$Title,
        [double]$X,
        [double]$Y,
        [double]$Width,
        [double]$Height,
        [System.Collections.IDictionary]$Roles
    )

    $queryState = [ordered]@{}
    foreach ($role in $Roles.Keys) {
        $queryState[$role] = @{ projections = @($Roles[$role]) }
    }

    $visual = @{
        visualType = $Type
        query = @{ queryState = $queryState }
        drillFilterOtherVisuals = $true
        visualContainerObjects = @{
            title = @(
                @{
                    properties = @{
                        text = @{ expr = @{ Literal = @{ Value = "'" + $Title + "'" } } }
                    }
                }
            )
        }
    }

    $container = @{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json"
        name = $Name
        position = @{ x = $X; y = $Y; z = 1000; width = $Width; height = $Height }
        visual = $visual
    }

    $visualPath = Join-Path (Join-Path $PagePath "visuals") $Name
    New-Item -ItemType Directory -Path $visualPath -Force | Out-Null
    $json = ConvertTo-Json -InputObject $container -Depth 100
    [System.IO.File]::WriteAllText(
        (Join-Path $visualPath "visual.json"),
        $json,
        (New-Object System.Text.UTF8Encoding -ArgumentList $false)
    )
}

function Add-Slicer {
    param([string]$PagePath, [string]$Name, [string]$Title, [string]$Entity, [string]$Property, [double]$X)
    $roles = [ordered]@{
        Values = @((New-Projection (New-ColumnField $Entity $Property) "$Entity.$Property"))
    }
    New-Visual $PagePath $Name "slicer" $Title $X 10 390 72 $roles
}

function Add-MeasureCard {
    param([string]$PagePath, [string]$Name, [string]$Title, [string]$Measure, [double]$X, [double]$Y, [double]$Width)
    $roles = [ordered]@{
        Values = @((New-Projection (New-MeasureField "vendas" $Measure) "vendas.$Measure"))
    }
    New-Visual $PagePath $Name "card" $Title $X $Y $Width 96 $roles
}

function Add-Page {
    param([string]$Name, [string]$DisplayName, [scriptblock]$BuildVisuals)
    $pagePath = Join-Path $pagesRoot $Name
    New-Item -ItemType Directory -Path $pagePath -Force | Out-Null
    $page = @{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.1.0/schema.json"
        name = $Name
        displayName = $DisplayName
        displayOption = "FitToPage"
        height = 720
        width = 1280
    }
    [System.IO.File]::WriteAllText(
        (Join-Path $pagePath "page.json"),
        (ConvertTo-Json -InputObject $page -Depth 50),
        (New-Object System.Text.UTF8Encoding -ArgumentList $false)
    )
    & $BuildVisuals $pagePath
}

Add-Page "VisaoGeral" "Visao geral" {
    param($page)
    Add-Slicer $page "FiltroAno" "Ano" "Calendario" "Ano" 10
    Add-Slicer $page "FiltroRegiao" "Regiao" "vendas" "regiao" 420
    Add-Slicer $page "FiltroVendedor" "Vendedor" "vendas" "vendedor" 830

    Add-MeasureCard $page "CardVendas" "Total de vendas" "Total Vendas" 15 100 300
    Add-MeasureCard $page "CardPedidos" "Pedidos" "Qtd Pedidos" 330 100 300
    Add-MeasureCard $page "CardTicket" "Ticket medio" "Ticket Medio" 645 100 300
    Add-MeasureCard $page "CardMediaVendedor" "Media por vendedor" "Media por Vendedor" 960 100 300

    $roles = [ordered]@{
        Category = @((New-Projection (New-ColumnField "Calendario" "Mes") "Calendario.Mes"))
        Y = @((New-Projection (New-MeasureField "vendas" "Total Vendas") "vendas.Total Vendas"))
    }
    New-Visual $page "EvolucaoMensal" "lineChart" "Vendas por mes" 15 215 610 475 $roles

    $roles = [ordered]@{
        Category = @((New-Projection (New-ColumnField "Calendario" "Semana") "Calendario.Semana"))
        Y = @((New-Projection (New-MeasureField "vendas" "Total Vendas") "vendas.Total Vendas"))
    }
    New-Visual $page "VendasSemana" "clusteredColumnChart" "Vendas por semana" 645 215 620 475 $roles
}

Add-Page "RegioesCidades" "Regioes e cidades" {
    param($page)
    Add-Slicer $page "FiltroAno" "Ano" "Calendario" "Ano" 10
    Add-Slicer $page "FiltroRegiao" "Regiao" "vendas" "regiao" 420
    Add-Slicer $page "FiltroVendedor" "Vendedor" "vendas" "vendedor" 830

    $roles = [ordered]@{
        Category = @((New-Projection (New-ColumnField "vendas" "regiao") "vendas.regiao"))
        Y = @((New-Projection (New-MeasureField "vendas" "Total Vendas") "vendas.Total Vendas"))
    }
    New-Visual $page "VendasPorRegiao" "clusteredBarChart" "Vendas por regiao" 15 105 465 570 $roles

    $roles = [ordered]@{
        Values = @(
            (New-Projection (New-ColumnField "vendas" "cidade") "vendas.cidade"),
            (New-Projection (New-ColumnField "vendas" "regiao") "vendas.regiao"),
            (New-Projection (New-MeasureField "vendas" "Total Vendas") "vendas.Total Vendas"),
            (New-Projection (New-MeasureField "vendas" "Regiao Abaixo da Media") "vendas.Regiao Abaixo da Media"),
            (New-Projection (New-MeasureField "vendas" "Variacao 3 Meses %") "vendas.Variacao 3 Meses %")
        )
    }
    New-Visual $page "DetalheCidades" "tableEx" "Desempenho por cidade" 495 105 770 570 $roles
}

Add-Page "Vendedores" "Vendedores" {
    param($page)
    Add-Slicer $page "FiltroAno" "Ano" "Calendario" "Ano" 10
    Add-Slicer $page "FiltroRegiao" "Regiao" "vendas" "regiao" 420
    Add-Slicer $page "FiltroVendedor" "Vendedor" "vendas" "vendedor" 830

    Add-MeasureCard $page "CardMediaVendedor" "Media por vendedor" "Media por Vendedor" 15 100 420

    $roles = [ordered]@{
        Category = @((New-Projection (New-ColumnField "vendas" "vendedor") "vendas.vendedor"))
        Y = @((New-Projection (New-MeasureField "vendas" "Total Vendas") "vendas.Total Vendas"))
    }
    New-Visual $page "RankingVendedores" "clusteredBarChart" "Ranking de vendas por vendedor" 15 210 480 460 $roles

    $roles = [ordered]@{
        Rows = @((New-Projection (New-ColumnField "vendas" "vendedor") "vendas.vendedor"))
        Columns = @((New-Projection (New-ColumnField "Calendario" "Mes") "Calendario.Mes"))
        Values = @((New-Projection (New-MeasureField "vendas" "Total Vendas") "vendas.Total Vendas"))
    }
    New-Visual $page "MatrizVendedorMes" "pivotTable" "Vendas por vendedor e mes" 510 100 755 570 $roles
}

$pageOrder = @("VisaoGeral", "RegioesCidades", "Vendedores")
$pagesMetadata = @{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.0.0/schema.json"
    pageOrder = $pageOrder
    activePageName = "VisaoGeral"
}
[System.IO.File]::WriteAllText(
    (Join-Path $pagesRoot "pages.json"),
    (ConvertTo-Json -InputObject $pagesMetadata -Depth 50),
    (New-Object System.Text.UTF8Encoding -ArgumentList $false)
)

$report = @{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/report/3.3.0/schema.json"
    themeCollection = @{}
}
[System.IO.File]::WriteAllText(
    (Join-Path $definitionRoot "report.json"),
    (ConvertTo-Json -InputObject $report -Depth 50),
    (New-Object System.Text.UTF8Encoding -ArgumentList $false)
)
[System.IO.File]::WriteAllText(
    (Join-Path $definitionRoot "version.json"),
    '{"$schema":"https://developer.microsoft.com/json-schemas/fabric/item/report/definition/versionMetadata/1.0.0/schema.json","version":"2.0.0"}',
    (New-Object System.Text.UTF8Encoding -ArgumentList $false)
)

$reportProperties = @{
    '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json"
    version = "4.0"
    datasetReference = @{ byPath = @{ path = "../Dashboard_Vendas.SemanticModel" } }
}
[System.IO.File]::WriteAllText(
    (Join-Path $reportRoot "definition.pbir"),
    (ConvertTo-Json -InputObject $reportProperties -Depth 50),
    (New-Object System.Text.UTF8Encoding -ArgumentList $false)
)
