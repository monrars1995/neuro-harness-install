# Instalador do Neuro Harness para Windows 10/11 (PowerShell 5.1+).
#
#   irm https://harness.neuros.my/install.ps1 | iex
#
# Com opções:
#   & ([scriptblock]::Create((irm https://harness.neuros.my/install.ps1))) -SemApp
#
#   -SemApp            não instala o app desktop
#   -Versao vX.Y.Z     instala uma versão específica (padrão: a última Release)
#   -SemCredenciais    não importa chaves de API do Hermes e do OpenCode
#   -SemAbrir          não sobe nem abre o Neuro Harness no fim
#   -Chave nh_…        usa a chave pessoal de instalação da sua conta Neuro
#   -GitHub            desenvolvimento: clona os repositórios públicos, sem a conta Neuro
#   -ClaudeCode        instala também os especialistas no Claude Code (plugins neuro-harness,
#                      neuro-mv-edit e neuro-ads-manager, marketplace local, sem GitHub)
#   -ApenasClaudeCode  só os plugins do Claude Code: sem o app, sem o painel e sem o runtime do Harness
#
# Este script é público e não contém segredos. Por padrão ele usa a sua conta Neuro: se este
# computador ainda não tiver uma chave, o navegador abre para você confirmar o acesso.
param([switch]$SemApp, [string]$Versao = "", [switch]$SemCredenciais, [switch]$SemAbrir, [string]$Chave = "", [switch]$GitHub,
      [switch]$ClaudeCode, [switch]$ApenasClaudeCode)
if ($ApenasClaudeCode) { $ClaudeCode = $true; $SemApp = $true; $SemCredenciais = $true; $SemAbrir = $true }
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repo = 'monrars1995/oneuros-harness'
$NH = if ($env:NEURO_HARNESS_HOME) { $env:NEURO_HARNESS_HOME } else { Join-Path $env:USERPROFILE '.neuro-harness' }
$Src = Join-Path $NH 'src'
$Bin = Join-Path $NH 'bin'
$Site = if ($env:NEURO_HARNESS_SITE) { $env:NEURO_HARNESS_SITE.TrimEnd('/') } else { 'https://harness.neuros.my' }
$AccessFile = Join-Path $NH 'acesso.json'
if (-not $Chave -and $env:NEURO_HARNESS_CHAVE) { $Chave = $env:NEURO_HARNESS_CHAVE }
if (-not $Chave -and (Test-Path $AccessFile)) { try { $Chave = (Get-Content $AccessFile -Raw | ConvertFrom-Json).key } catch {} }

function Say($m) { Write-Host "▸ $m" -ForegroundColor White }
function Ok($m) { Write-Host "  ✓ $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  ! $m" -ForegroundColor Yellow }
function Die($m) { Write-Host "✗ $m" -ForegroundColor Red; throw $m }
function Has($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function RefreshPath { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }
function NodeOk { if (-not (Has node)) { return $false }; try { [int](node -p "process.versions.node.split('.')[0]") -ge 22 } catch { $false } }
function PythonOk { if (-not (Has python)) { return $false }; try { python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" 2>$null; $LASTEXITCODE -eq 0 } catch { $false } }

Write-Host ""
Write-Host "neuro harness — instalador (Windows)" -ForegroundColor White
Write-Host ""

# Modo: conta Neuro (chave pessoal; o padrão) ou GitHub (só desenvolvimento).
# O código é público, mas os agentes só se instalam com a conta Neuro aprovada. -GitHub é para desenvolvimento.
$Mode = 'conta'
if ($GitHub) { $Mode = 'github'; $env:NEURO_HARNESS_DEV = '1' }

function FetchPkg($url, $out) {
  try { Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Bearer $Chave" } -OutFile $out -UseBasicParsing }
  catch {
    $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
    switch ($code) {
      401 { Die "chave inválida ou revogada. Gere outra em $Site/conta" }
      403 { Die "o acesso desta conta não está aprovado. Acompanhe em $Site/conta" }
      501 { Die 'o site ainda não está servindo os pacotes. Tente mais tarde.' }
      default { Die "não consegui baixar $url ($code)" }
    }
  }
}

# ---------------------------------------------------------------- 1. dependências
Say 'Conferindo dependências'
if (-not (Has winget)) { Die 'winget não encontrado. Instale o "Instalador de Aplicativo" pela Microsoft Store e rode de novo.' }
$pkgs = @()
if (-not (NodeOk)) { $pkgs += 'OpenJS.NodeJS.LTS' }
if (-not (Has git)) { $pkgs += 'Git.Git' }
if (-not (PythonOk)) { $pkgs += 'Python.Python.3.12' }
if (-not (Has ffmpeg)) { $pkgs += 'Gyan.FFmpeg' }
if ($Mode -eq 'github' -and -not (Has gh)) { $pkgs += 'GitHub.cli' }
foreach ($id in $pkgs) {
  Say "Instalando $id"
  winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements | Out-Host
}
RefreshPath
if (-not (NodeOk)) { Die 'Node.js 22+ não encontrado. Feche e abra o PowerShell e rode de novo.' }
$need = @('git', 'ffmpeg', 'tar'); if ($Mode -eq 'github') { $need += 'gh' }
foreach ($c in $need) { if (-not (Has $c)) { Die "$c não encontrado. Feche e abra o PowerShell e rode de novo." } }
if (-not (PythonOk)) { Die 'Python 3.10+ não encontrado. Feche e abra o PowerShell e rode de novo.' }
Ok "Node $(node -v) · git · Python · FFmpeg"

# ---------------------------------------------------------------- 2. acesso
New-Item -ItemType Directory -Force -Path $NH, $Bin | Out-Null
if ($Mode -eq 'conta') {
  Say 'Conta Neuro'
  if (-not $Chave) {
    Write-Host '  O navegador vai abrir para você entrar na sua conta Neuro e confirmar este computador.' -ForegroundColor DarkGray
    Write-Host "  Ainda sem acesso? Peça em $Site/acesso" -ForegroundColor DarkGray
    try { $c = Invoke-RestMethod -Method Post -Uri "$Site/api/dispositivo/codigo" -ContentType 'application/json' -Body '{}' }
    catch { Die 'O login pela conta Neuro ainda não está ligado no site.' }
    Write-Host ""; Write-Host "  Confirme em: $($c.url)"; Write-Host "  Código: $($c.codigo)"; Write-Host ""
    Start-Process $c.url | Out-Null
    Write-Host '  Aguardando a confirmação (até 10 minutos)...'
    $end = (Get-Date).AddMinutes(10)
    while ((Get-Date) -lt $end -and -not $Chave) {
      Start-Sleep -Seconds 3
      try { $st = Invoke-RestMethod -Uri ("$Site/api/dispositivo/status?codigo=" + [uri]::EscapeDataString($c.codigo) + '&segredo=' + [uri]::EscapeDataString($c.segredo)) } catch { continue }
      if ($st.estado -eq 'confirmado') {
        $k = Invoke-RestMethod -Method Post -Uri "$Site/api/dispositivo/resgatar" -ContentType 'application/json' -Body (@{ codigo = $c.codigo; segredo = $c.segredo } | ConvertTo-Json)
        $Chave = $k.key
      } elseif ('expirado', 'invalido', 'usado' -contains $st.estado) { break }
    }
    if (-not $Chave) { Die 'A confirmação não chegou a tempo. Rode o instalador de novo.' }
  }
  @{ key = $Chave; site = $Site; maquina = $env:COMPUTERNAME; savedAt = (Get-Date).ToString('o') } | ConvertTo-Json | Set-Content -Path $AccessFile -Encoding UTF8
  icacls $AccessFile /inheritance:r /grant:r "${env:USERNAME}:(R,W)" | Out-Null
  $env:NEURO_HARNESS_SITE = $Site
  Ok ("computador conectado à sua conta (chave " + $Chave.Substring(0, 6) + "…)")

  if (-not $Versao) { $Versao = 'latest' }
  Say "Baixando o Neuro Harness $Versao"
  $tmp = Join-Path $env:TEMP ("neuro-harness-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  FetchPkg "$Site/api/pacotes/neuro-harness/$Versao" (Join-Path $tmp 'nh.tgz')
  $new = "$Src.new"
  if (Test-Path $new) { Remove-Item -Recurse -Force $new }
  New-Item -ItemType Directory -Force -Path $new | Out-Null
  tar -xzf (Join-Path $tmp 'nh.tgz') -C $new --strip-components=1
  if ($LASTEXITCODE -ne 0) { Die 'pacote corrompido' }
  if (Test-Path $Src) { Remove-Item -Recurse -Force $Src }
  Move-Item $new $Src
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  $Versao = 'v' + (node -p "require(process.argv[1]).version" (Join-Path $Src 'package.json'))
  Ok "código em $Src ($Versao)"
} else {
Say 'Login no GitHub (modo desenvolvimento)'
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host '  O navegador vai abrir para você entrar no GitHub (modo desenvolvimento).' -ForegroundColor DarkGray
  gh auth login --web --git-protocol https --hostname github.com
}
gh auth setup-git 2>$null | Out-Null
gh api "repos/$Repo" --jq .full_name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Die "Sua conta do GitHub não tem acesso a $Repo. Peça acesso em $Site/acesso" }
Ok "conectado como $(gh api user --jq .login)"

# ---------------------------------------------------------------- 3. Neuro Harness
if (-not $Versao) { $Versao = gh release view --repo $Repo --json tagName --jq .tagName }
Say "Baixando o Neuro Harness $Versao"
if (Test-Path (Join-Path $Src '.git')) {
  git -C $Src fetch -q --depth 1 origin "refs/tags/${Versao}:refs/tags/$Versao" --force
  git -C $Src -c advice.detachedHead=false checkout -q $Versao
} else {
  if (Test-Path $Src) { Remove-Item -Recurse -Force $Src }
  git -c advice.detachedHead=false clone -q --depth 1 --branch $Versao "https://github.com/$Repo.git" $Src
}
Ok "código em $Src"

}

$Cli = Join-Path $Src 'lib\cli.js'
Set-Content -Path (Join-Path $Bin 'neuro-harness.cmd') -Value "@echo off`r`nnode `"$Cli`" %*" -Encoding ASCII
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not ($userPath -split ';' | Where-Object { $_ -eq $Bin })) {
  [Environment]::SetEnvironmentVariable('Path', ($Bin + ';' + $userPath).TrimEnd(';'), 'User')
}
$env:Path = "$Bin;$env:Path"
Ok "comando neuro-harness em $Bin (vale nos terminais novos)"

if ($ApenasClaudeCode) {
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Die 'o Claude Code não está instalado (comando claude): https://claude.com/claude-code' }
} else {
  Say 'Instalando o Neuro Harness e os agentes (a primeira vez baixa ~550 MB)'
  node $Cli setup
  if ($LASTEXITCODE -ne 0) { Die 'o setup falhou; rode: neuro-harness doctor' }
}

if ($ClaudeCode) {
  Say 'Instalando os especialistas no Claude Code'
  node $Cli claude instalar
  if ($LASTEXITCODE -ne 0) { Warn 'os plugins do Claude Code não foram instalados (rode: neuro-harness claude instalar)' }
}

$hermes = Join-Path $env:USERPROFILE '.hermes\.env'
$opencode = Join-Path $env:USERPROFILE '.local\share\opencode\auth.json'
if (-not $SemCredenciais -and ((Test-Path $hermes) -or (Test-Path $opencode))) {
  Say 'Importando chaves de API do Hermes e do OpenCode'
  node $Cli credenciais
}

# ---------------------------------------------------------------- 4. app desktop
if (-not $SemApp) {
  Say 'Instalando o app Neuro Harness'
  $tmp = Join-Path $env:TEMP ("neuro-harness-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  if ($Mode -eq 'conta') { FetchPkg "$Site/api/app/windows" (Join-Path $tmp 'Neuro-Harness-Setup.exe') }
  else { gh release download $Versao --repo $Repo --pattern '*Setup*.exe' --dir $tmp --clobber }
  $exe = Get-ChildItem $tmp -Filter '*.exe' | Select-Object -First 1
  if ($exe) {
    Start-Process -FilePath $exe.FullName -ArgumentList '/S' -Wait
    Ok 'app instalado (menu Iniciar: Neuro Harness)'
  } else { Warn 'instalador do app não encontrado na Release' }
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------- 5. pronto
if (-not $SemAbrir) {
  Say 'Subindo o Neuro Harness'
  node $Cli start
  node $Cli open | Out-Null
}

if ($ApenasClaudeCode) {
  Write-Host ""
  Write-Host "Especialistas do Neuro Harness instalados no Claude Code." -ForegroundColor Green
  Write-Host "  Abra uma sessão nova do Claude Code e comece com /neuro-harness:comecar"
  Write-Host "  neuro-harness claude status     versões dos plugins"
  Write-Host "  neuro-harness claude instalar   atualiza depois de uma versão nova"
  Write-Host "Abra um terminal novo para usar o comando neuro-harness." -ForegroundColor DarkGray
} else {
Write-Host ""
Write-Host "Neuro Harness instalado." -ForegroundColor Green
Write-Host "  neuro-harness status      estado e endereço do painel"
Write-Host "  neuro-harness open        abre o painel no navegador"
Write-Host "  neuro-harness doctor      confere tudo"
Write-Host "  neuro-harness setup       atualiza depois de uma versão nova"
Write-Host "  neuro-harness conta       mostra a conta conectada a este computador"
if (-not $ClaudeCode -and (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Host "  neuro-harness claude instalar   leva os especialistas para o Claude Code (o Claude Code está neste computador)"
}
Write-Host "Abra um terminal novo para usar o comando neuro-harness." -ForegroundColor DarkGray
}
