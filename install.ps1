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
#
# Este script é público e não contém segredos. Os repositórios do Neuro Harness são privados:
# o script faz o login no GitHub (gh) e usa as suas credenciais para baixar o resto.
param([switch]$SemApp, [string]$Versao = "", [switch]$SemCredenciais, [switch]$SemAbrir)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repo = 'monrars1995/neuro-harness'
$NH = if ($env:NEURO_HARNESS_HOME) { $env:NEURO_HARNESS_HOME } else { Join-Path $env:USERPROFILE '.neuro-harness' }
$Src = Join-Path $NH 'src'
$Bin = Join-Path $NH 'bin'

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

# ---------------------------------------------------------------- 1. dependências
Say 'Conferindo dependências'
if (-not (Has winget)) { Die 'winget não encontrado. Instale o "Instalador de Aplicativo" pela Microsoft Store e rode de novo.' }
$pkgs = @()
if (-not (NodeOk)) { $pkgs += 'OpenJS.NodeJS.LTS' }
if (-not (Has git)) { $pkgs += 'Git.Git' }
if (-not (PythonOk)) { $pkgs += 'Python.Python.3.12' }
if (-not (Has ffmpeg)) { $pkgs += 'Gyan.FFmpeg' }
if (-not (Has gh)) { $pkgs += 'GitHub.cli' }
foreach ($id in $pkgs) {
  Say "Instalando $id"
  winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements | Out-Host
}
RefreshPath
if (-not (NodeOk)) { Die 'Node.js 22+ não encontrado. Feche e abra o PowerShell e rode de novo.' }
foreach ($c in 'git', 'ffmpeg', 'gh') { if (-not (Has $c)) { Die "$c não encontrado. Feche e abra o PowerShell e rode de novo." } }
if (-not (PythonOk)) { Die 'Python 3.10+ não encontrado. Feche e abra o PowerShell e rode de novo.' }
Ok "Node $(node -v) · git · Python · FFmpeg · GitHub CLI"

# ---------------------------------------------------------------- 2. login no GitHub
Say 'Login no GitHub (repositórios privados)'
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host '  O navegador vai abrir para você entrar no GitHub com a conta que tem acesso ao Neuro Harness.' -ForegroundColor DarkGray
  gh auth login --web --git-protocol https --hostname github.com
}
gh auth setup-git 2>$null | Out-Null
gh api "repos/$Repo" --jq .full_name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Die "Sua conta do GitHub não tem acesso a $Repo. Peça acesso ao dono do repositório." }
Ok "conectado como $(gh api user --jq .login)"

# ---------------------------------------------------------------- 3. Neuro Harness
if (-not $Versao) { $Versao = gh release view --repo $Repo --json tagName --jq .tagName }
Say "Baixando o Neuro Harness $Versao"
New-Item -ItemType Directory -Force -Path $NH, $Bin | Out-Null
if (Test-Path (Join-Path $Src '.git')) {
  git -C $Src fetch -q --depth 1 origin "refs/tags/${Versao}:refs/tags/$Versao" --force
  git -C $Src -c advice.detachedHead=false checkout -q $Versao
} else {
  if (Test-Path $Src) { Remove-Item -Recurse -Force $Src }
  git -c advice.detachedHead=false clone -q --depth 1 --branch $Versao "https://github.com/$Repo.git" $Src
}
Ok "código em $Src"

$Cli = Join-Path $Src 'lib\cli.js'
Set-Content -Path (Join-Path $Bin 'neuro-harness.cmd') -Value "@echo off`r`nnode `"$Cli`" %*" -Encoding ASCII
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not ($userPath -split ';' | Where-Object { $_ -eq $Bin })) {
  [Environment]::SetEnvironmentVariable('Path', ($Bin + ';' + $userPath).TrimEnd(';'), 'User')
}
$env:Path = "$Bin;$env:Path"
Ok "comando neuro-harness em $Bin (vale nos terminais novos)"

Say 'Instalando o Harness, o motor, o perfil e os plugins (a primeira vez baixa ~550 MB)'
node $Cli setup
if ($LASTEXITCODE -ne 0) { Die 'o setup falhou; rode: neuro-harness doctor' }

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
  gh release download $Versao --repo $Repo --pattern '*Setup*.exe' --dir $tmp --clobber
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

Write-Host ""
Write-Host "Neuro Harness instalado." -ForegroundColor Green
Write-Host "  neuro-harness status      estado e endereço do painel"
Write-Host "  neuro-harness open        abre o painel no navegador"
Write-Host "  neuro-harness doctor      confere tudo"
Write-Host "  neuro-harness setup       atualiza depois de uma versão nova"
Write-Host "Construído sobre o DeepSeek Harness. Abra um terminal novo para usar o comando neuro-harness." -ForegroundColor DarkGray
