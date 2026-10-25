# Lista todos os textos visíveis do jogo em build/texts.csv (arquivo, local, texto).
# Fontes: campos de texto dos JSON de game/data (inclusive rooms/) e literais dos scripts/cenas
# dentro de label/button/primary/secondary/ghost/chip/toast_requested.emit, "text = " e retornos
# de *_error (e similares). Mesma lógica de game/tests/texts_test.gd: ao mudar uma, mude a outra.
# Uso: powershell -ExecutionPolicy Bypass -File tools\list_texts.ps1 [-Out build\texts.csv]
# -ByScreen (Interface 2, etapa 11): agrupa os textos dos scripts de interface pela tela do tour e conta
# palavras (fora números, %d/%s e sinais), mostrando as frases mais longas de cada tela. O limite por tela
# fica em game/tests/text_budget_test.gd.
param([string]$Out = "build/texts.csv", [switch]$ByScreen)
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$root = Join-Path (Get-Location).Path "game"
$rows = New-Object System.Collections.Generic.List[object]

# Campos JSON cujo valor é texto mostrado ao jogador.
$jsonKeys = @("name", "description", "label", "dialogue", "map_name", "map_caption", "instruction", "action_label",
    "queue_label", "recipe_label", "hint", "introduction", "postcard", "note", "unlocks_text", "role", "greeting",
    "text", "how_to", "breed", "announcement", "away_text", "unlock_label", "title", "caption", "detail_label",
    "overview_label", "button", "equip", "friend_gift")

function Add-Json($node, [string]$path, [string]$key, [string]$file) {
    if ($node -is [string]) {
        if ($jsonKeys -contains $key -and $node -match '\p{L}') { $rows.Add([pscustomobject]@{ arquivo = $file; local = $path; texto = $node }) }
    } elseif ($node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $node.PSObject.Properties) { Add-Json $p.Value "$path/$($p.Name)" $p.Name $file }
    } elseif ($node -is [System.Collections.IEnumerable]) {
        $i = 0
        foreach ($x in $node) { Add-Json $x "$path[$i]" $key $file; $i++ }
    }
}
foreach ($f in Get-ChildItem (Join-Path $root "data") -Recurse -Filter *.json) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace("\", "/")
    $json = [IO.File]::ReadAllText($f.FullName, $utf8) | ConvertFrom-Json
    Add-Json $json "" "" $rel
}

# Chamadas de interface e atribuições de texto nos scripts e cenas.
$callPattern = '(?<![A-Za-z_])(label|short_label|fill_label|button|primary|secondary|ghost|chip|pill|lock_hint|toast_requested\.emit|show_toast|_show_toast)\(|\.text\s*=|^\s*text\s*=|\blabel\s*=|\bcaption\s*=|\btitle\s*='
$funcPattern = '(_error|_text|_label|_hint|_name|_caption|describe)\b'
$literal = [regex]'"((?:[^"\\]|\\.)*)"'
$files = @(Get-ChildItem (Join-Path $root "scripts") -Recurse -Filter *.gd) + @(Get-ChildItem (Join-Path $root "scenes") -Recurse -Include *.gd, *.tscn) + @(Get-Item (Join-Path $root "autoload/game_state.gd"))
foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace("\", "/")
    $lines = [IO.File]::ReadAllLines($f.FullName, $utf8)
    $func = ""
    for ($n = 0; $n -lt $lines.Count; $n++) {
        $line = $lines[$n]
        if ($line -match '^\s*(?:static\s+)?func\s+(\w+)') { $func = $Matches[1] }
        $code = $line
        if ($f.Extension -eq ".gd") { $code = $line -replace '(^|\s)#.*$', '' }
        if ($code -match '^\s*(print|push_error|push_warning|assert|@export|const\s+\w+\s*:?=?\s*preload)\b' -or $code -match '\b(preload|load|get_node|has_node|find_child)\(') { continue }
        $sure = ($code -match $callPattern) -or ($code -match '^\s*return\s+"' -and $func -match $funcPattern)
        foreach ($m in $literal.Matches($code)) {
            $t = $m.Groups[1].Value
            if ($t -notmatch '\p{L}') { continue }
            if (-not $sure -and $t -notmatch '\s' -and $t -cnotmatch '^[A-Z]') { continue }
            if ($t -match '^(res://|user://|ui:|%|#|\w+[:/_]\w+$)' -or $t -match '^[a-z0-9_]+$') { continue }
            $rows.Add([pscustomobject]@{ arquivo = $rel; local = ($n + 1).ToString() + " " + $func; texto = $t })
        }
    }
}

New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
$rows | Export-Csv -Path $Out -NoTypeInformation -Encoding UTF8
Write-Host "$($rows.Count) textos em $Out"

if ($ByScreen) {
    # Tela do tour <- arquivos de interface que a montam.
    $screens = [ordered]@{
        "Tiro"           = "pet_screen|pet_care_tray|pet_notebook|wish_ui|hud\.gd|pillar_ui"
        "Missões"        = "tasks_screen|quest_guide|next_step|task_help"
        "Mochila"        = "bag_screen|inventory_list"
        "Mundo/Mapa"     = "worlds_screen|world_selector|world_card|room\.gd|places\.gd|world_pin"
        "Bandejas"       = "station_tray|action_tray|plot_tray|farm_dock|nature_ui"
        "Painéis"        = "growth_ui|market_ui|project_ui|house_ui|friend_ui|album_view|settings_panel|sheet_builder|progression_ui"
        "Folhas/cartões" = "celebration|walk_result|welcome_back|reward_sheet|modal_card|growth_ceremony|quest_reward"
    }
    foreach ($name in $screens.Keys) {
        $set = $rows | Where-Object { ($_.arquivo -like "scripts/*" -or $_.arquivo -like "scenes/*") -and $_.arquivo -match $screens[$name] }
        $counted = @(foreach ($r in $set) {
            $words = @(($r.texto -replace '%[-+0-9.]*[a-z]', ' ') -split '\s+' | Where-Object { $_ -match '\p{L}' })
            [pscustomobject]@{ arquivo = $r.arquivo; texto = $r.texto; palavras = $words.Count }
        })
        $sum = ($counted | Measure-Object palavras -Sum).Sum
        Write-Host ("== {0}: {1} textos, {2} palavras" -f $name, $counted.Count, $sum)
        foreach ($l in ($counted | Sort-Object palavras -Descending | Select-Object -First 6)) {
            Write-Host ("   {0,2}  {1}  ({2})" -f $l.palavras, $l.texto, $l.arquivo)
        }
    }
}
