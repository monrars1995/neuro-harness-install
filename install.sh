#!/usr/bin/env bash
# Instalador do Neuro Harness para macOS e Linux.
#
#   curl -fsSL https://harness.neuros.my/install.sh | bash
#
# Opções (depois de "bash -s --"):
#   --sem-app           não baixa o app desktop (macOS)
#   --versao vX.Y.Z     instala uma versão específica (padrão: a última Release)
#   --sem-credenciais   não importa chaves de API do Hermes e do OpenCode
#   --sem-abrir         não sobe nem abre o Neuro Harness no fim
#   --chave nh_…        usa a chave pessoal de instalação da sua conta Neuro
#   --github            instala pelo GitHub (conta com acesso aos repositórios), como antes
#   --claude-code       instala também os especialistas no Claude Code (plugins neuro-harness,
#                       neuro-mv-edit e neuro-ads-manager, marketplace local, sem GitHub)
#   --apenas-claude-code  só os plugins do Claude Code: sem o app, sem o painel e sem o runtime do Harness
#
# Este script é público e não contém segredos. Por padrão ele usa a sua conta Neuro: se este
# computador ainda não tiver uma chave, o navegador abre para você confirmar o acesso.
# Quem já tem o GitHub com acesso aos repositórios continua instalando por ele.
set -euo pipefail

REPO="monrars1995/neuro-harness"
NH_HOME="${NEURO_HARNESS_HOME:-$HOME/.neuro-harness}"
SRC="$NH_HOME/src"
SITE="${NEURO_HARNESS_SITE:-https://harness.neuros.my}"
WITH_APP=1; VERSION=""; CREDS=1; OPEN=1; KEY="${NEURO_HARNESS_CHAVE:-}"; FORCE_GH=0; CLAUDE=0; ONLY_CLAUDE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --sem-app) WITH_APP=0 ;;
    --versao) VERSION="${2:-}"; shift ;;
    --sem-credenciais) CREDS=0 ;;
    --sem-abrir) OPEN=0 ;;
    --chave) KEY="${2:-}"; shift ;;
    --github) FORCE_GH=1 ;;
    --claude-code) CLAUDE=1 ;;
    --apenas-claude-code|--so-claude-code) CLAUDE=1; ONLY_CLAUDE=1; WITH_APP=0; CREDS=0; OPEN=0 ;;
    -h|--help) sed -n '2,19p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[90m'; X=$'\033[0m'
say()  { printf '%s▸ %s%s\n' "$B" "$*" "$X"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$X" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$X" "$*"; }
die()  { printf '%s✗ %s%s\n' "$R" "$*" "$X" >&2; exit 1; }
tty()  { if [ -r /dev/tty ]; then "$@" </dev/tty; else "$@"; fi; }
has()  { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"; ARCH="$(uname -m)"
printf '\n%sneuro harness%s %s— instalador (%s %s)%s\n\n' "$B" "$X" "$D" "$OS" "$ARCH" "$X"

node_ok()   { has node && [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)" -ge 22 ]; }
python_ok() { has python3 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; }

# Modo: conta Neuro (chave pessoal, sem GitHub) ou GitHub (conta com acesso aos repositórios).
ACCESS_FILE="$NH_HOME/acesso.json"
[ -z "$KEY" ] && [ -f "$ACCESS_FILE" ] && KEY="$(sed -n 's/.*"key": *"\(nh_[^"]*\)".*/\1/p' "$ACCESS_FILE" | head -1)"
MODE=conta
if [ "$FORCE_GH" = 1 ]; then MODE=github
elif [ -z "$KEY" ] && has gh && gh auth status >/dev/null 2>&1 && gh api "repos/$REPO" --jq .full_name >/dev/null 2>&1; then MODE=github
fi

# ---------------------------------------------------------------- 1. dependências
deps_mac() {
  if ! has brew; then
    say "Instalando o Homebrew (o macOS vai pedir a sua senha)"
    tty /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)" && break; done
  has brew || die "Homebrew não encontrado depois da instalação."
  local pkgs=()
  node_ok || pkgs+=(node)
  has git || pkgs+=(git)
  python_ok || pkgs+=(python)
  has ffmpeg || pkgs+=(ffmpeg)
  [ "$MODE" = github ] && ! has gh && pkgs+=(gh)
  if [ ${#pkgs[@]} -gt 0 ]; then say "Instalando: ${pkgs[*]}"; brew install "${pkgs[@]}"; fi
}

asroot() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

deps_linux() {
  if has apt-get; then
    say "Instalando dependências (apt; o sudo pode pedir a sua senha)"
    asroot apt-get update -y
    asroot apt-get install -y git python3 ffmpeg curl ca-certificates gnupg
    if ! node_ok; then
      say "Instalando o Node.js 22 (NodeSource)"
      curl -fsSL https://deb.nodesource.com/setup_22.x | asroot bash -
      asroot apt-get install -y nodejs
    fi
    if [ "$MODE" = github ] && ! has gh; then
      say "Instalando o GitHub CLI"
      asroot mkdir -p -m 755 /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | asroot tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
      asroot chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | asroot tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      asroot apt-get update -y && asroot apt-get install -y gh
    fi
  elif has dnf; then
    say "Instalando dependências (dnf; o sudo pode pedir a sua senha)"
    asroot dnf install -y git python3 ffmpeg-free curl || asroot dnf install -y git python3 ffmpeg curl
    node_ok || { curl -fsSL https://rpm.nodesource.com/setup_22.x | asroot bash -; asroot dnf install -y nodejs; }
    [ "$MODE" = github ] && ! has gh && asroot dnf install -y gh
  elif has pacman; then
    say "Instalando dependências (pacman; o sudo pode pedir a sua senha)"
    asroot pacman -Sy --needed --noconfirm git python ffmpeg nodejs npm
    [ "$MODE" = github ] && asroot pacman -S --needed --noconfirm github-cli
  else
    die "Gerenciador de pacotes não suportado. Instale à mão: Node.js 22+, git, Python 3.10+ e FFmpeg."
  fi
}

say "Conferindo dependências"
case "$OS" in
  Darwin) deps_mac ;;
  Linux) deps_linux ;;
  *) die "Sistema não suportado: $OS (no Windows, use install.ps1)" ;;
esac
node_ok || die "Node.js 22+ não encontrado."
for c in git ffmpeg curl tar; do has "$c" || die "$c não encontrado."; done
[ "$MODE" = github ] && { has gh || die "gh não encontrado."; }
python_ok || die "Python 3.10+ não encontrado."
ok "Node $(node -v) · git · Python · FFmpeg"


# ---------------------------------------------------------------- 2. acesso
# Baixa um pacote privado pelo site com a chave (cabeçalho em arquivo: a chave não aparece na lista de processos).
fetch_pkg() { # fetch_pkg <url> <saída>
  local H; H="$(mktemp)"; chmod 600 "$H"
  printf 'Authorization: Bearer %s\n' "$KEY" > "$H"
  local code; code="$(curl -fsSL --retry 2 -H "@$H" -o "$2" -w '%{http_code}' "$1" || true)"
  rm -f "$H"
  [ -s "$2" ] || { case "$code" in 401) die "chave inválida ou revogada. Gere outra em $SITE/conta" ;; 403) die "o acesso desta conta não está aprovado. Acompanhe em $SITE/conta" ;; 501) die "o site ainda não está servindo os pacotes. Tente mais tarde." ;; *) die "não consegui baixar $1 (HTTP ${code:-?})" ;; esac; }
}

if [ "$MODE" = conta ]; then
  say "Conta Neuro"
  mkdir -p "$NH_HOME"
  if [ -z "$KEY" ]; then
    printf '  %sO navegador vai abrir para você entrar na sua conta Neuro e confirmar este computador.%s\n' "$D" "$X"
    printf '  %sAinda sem acesso? Peça em %s/acesso%s\n' "$D" "$SITE" "$X"
    LOGIN_JS="$(mktemp)"
    cat > "$LOGIN_JS" <<'NODE'
const fs = require('fs'), os = require('os'), { spawnSync } = require('child_process')
const site = process.env.NH_SITE, file = process.env.NH_FILE
const api = async (p, o = {}) => { const r = await fetch(site + p, { ...o, headers: { 'Content-Type': 'application/json' } }); let d = {}; try { d = await r.json() } catch {} ; return { ok: r.ok, status: r.status, d } }
;(async () => {
  const c = await api('/api/dispositivo/codigo', { method: 'POST', body: '{}' })
  if (!c.ok) { console.error(c.status === 503 ? 'O login pela conta Neuro ainda não está ligado no site.' : 'Não consegui iniciar o login (HTTP ' + c.status + ').'); process.exit(1) }
  const { codigo, segredo, url } = c.d
  console.log('\n  Confirme em: ' + url + '\n  Código: ' + codigo + '\n')
  spawnSync(process.platform === 'darwin' ? 'open' : 'xdg-open', [url], { stdio: 'ignore' })
  console.log('  Aguardando a confirmação (até 10 minutos)...')
  for (const end = Date.now() + 600e3; Date.now() < end;) {
    await new Promise((r) => setTimeout(r, 3000))
    const s = await api('/api/dispositivo/status?codigo=' + encodeURIComponent(codigo) + '&segredo=' + encodeURIComponent(segredo)).catch(() => ({ d: {} }))
    if (s.d.estado === 'confirmado') {
      const k = await api('/api/dispositivo/resgatar', { method: 'POST', body: JSON.stringify({ codigo, segredo }) })
      if (!k.ok) break
      fs.writeFileSync(file, JSON.stringify({ key: k.d.key, site, maquina: os.hostname(), savedAt: new Date().toISOString() }, null, 2) + '\n', { mode: 0o600 })
      process.exit(0)
    }
    if (['expirado', 'invalido', 'usado'].includes(s.d.estado)) break
  }
  console.error('A confirmação não chegou a tempo. Rode o instalador de novo.'); process.exit(1)
})()
NODE
    NH_SITE="$SITE" NH_FILE="$ACCESS_FILE" node "$LOGIN_JS" || { rm -f "$LOGIN_JS"; die "login não concluído."; }
    rm -f "$LOGIN_JS"
    KEY="$(sed -n 's/.*"key": *"\(nh_[^"]*\)".*/\1/p' "$ACCESS_FILE" | head -1)"
    [ -n "$KEY" ] || die "não recebi a chave da sua conta."
  else
    umask 077; printf '{\n  "key": "%s",\n  "site": "%s"\n}\n' "$KEY" "$SITE" > "$ACCESS_FILE"; umask 022
  fi
  chmod 600 "$ACCESS_FILE"
  export NEURO_HARNESS_SITE="$SITE"
  ok "computador conectado à sua conta (chave ${KEY:0:6}…${KEY: -4})"

  # NEURO_HARNESS_REF (teste) não vale aqui: a conta instala sempre uma Release.
  [ -n "$VERSION" ] || VERSION=latest
  say "Baixando o Neuro Harness ${VERSION#v}"
  TMP="$(mktemp -d)"
  fetch_pkg "$SITE/api/pacotes/neuro-harness/$VERSION" "$TMP/nh.tgz"
  rm -rf "$SRC.new"; mkdir -p "$SRC.new"
  tar -xzf "$TMP/nh.tgz" -C "$SRC.new" --strip-components=1 || die "pacote corrompido"
  rm -rf "$SRC"; mv "$SRC.new" "$SRC"; rm -rf "$TMP"
  VERSION="v$(node -p "require('$SRC/package.json').version")"
  ok "código em $SRC ($VERSION)"
else
say "Login no GitHub (repositórios privados)"
if ! gh auth status >/dev/null 2>&1; then
  printf '  %sO navegador vai abrir para você entrar no GitHub com a conta que tem acesso ao Neuro Harness.%s\n' "$D" "$X"
  tty gh auth login --web --git-protocol https --hostname github.com
fi
gh auth setup-git >/dev/null 2>&1 || true
gh api "repos/$REPO" --jq .full_name >/dev/null 2>&1 || die "Sua conta do GitHub não tem acesso a $REPO. Peça acesso em $SITE/acesso"
ok "conectado como $(gh api user --jq .login)"

# ---------------------------------------------------------------- 3. Neuro Harness
# NEURO_HARNESS_REF (teste): instala de uma branch em vez de uma Release
REF="${NEURO_HARNESS_REF:-}"
[ -n "$VERSION" ] || [ -n "$REF" ] || VERSION="$(gh release view --repo "$REPO" --json tagName --jq .tagName)"
[ -n "$REF" ] && VERSION="$REF"
say "Baixando o Neuro Harness $VERSION"
mkdir -p "$NH_HOME"
if [ -d "$SRC/.git" ] && [ -n "$REF" ]; then
  git -C "$SRC" fetch -q --depth 1 origin "$REF" && git -C "$SRC" -c advice.detachedHead=false checkout -q FETCH_HEAD
elif [ -d "$SRC/.git" ]; then
  git -C "$SRC" fetch -q --depth 1 origin "refs/tags/$VERSION:refs/tags/$VERSION" --force
  git -C "$SRC" -c advice.detachedHead=false checkout -q "$VERSION"
else
  rm -rf "$SRC"
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$VERSION" "https://github.com/$REPO.git" "$SRC"
fi
ok "código em $SRC"
fi

mkdir -p "$NH_HOME/bin"
cat > "$NH_HOME/bin/neuro-harness" <<EOF
#!/bin/sh
exec node "$SRC/lib/cli.js" "\$@"
EOF
chmod 755 "$NH_HOME/bin/neuro-harness"
LINE="export PATH=\"$NH_HOME/bin:\$PATH\"  # neuro-harness"
[ "${NEURO_HARNESS_NO_RC:-0}" = 1 ] || for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  if [ -f "$rc" ] || [ "$rc" = "$HOME/.profile" ]; then
    grep -qs "# neuro-harness" "$rc" || printf '\n%s\n' "$LINE" >> "$rc"
  fi
done
export PATH="$NH_HOME/bin:$PATH"
ok "comando neuro-harness em $NH_HOME/bin (vale nos terminais novos)"

if [ "$ONLY_CLAUDE" = 1 ]; then
  command -v claude >/dev/null 2>&1 || die "o Claude Code não está instalado (comando claude): https://claude.com/claude-code"
else
  say "Instalando o Neuro Harness e os agentes (a primeira vez baixa ~550 MB)"
  node "$SRC/lib/cli.js" setup
fi

if [ "$CLAUDE" = 1 ]; then
  say "Instalando os especialistas no Claude Code"
  node "$SRC/lib/cli.js" claude instalar || warn "os plugins do Claude Code não foram instalados (rode: neuro-harness claude instalar)"
fi

if [ "$CREDS" = 1 ] && { [ -f "$HOME/.hermes/.env" ] || [ -f "$HOME/.local/share/opencode/auth.json" ]; }; then
  say "Importando chaves de API do Hermes e do OpenCode"
  node "$SRC/lib/cli.js" credenciais || warn "não foi possível importar as chaves agora (rode: neuro-harness credenciais)"
fi

# ---------------------------------------------------------------- 4. app desktop (macOS Apple Silicon)
if [ "$WITH_APP" = 1 ] && [ "$OS" = "Darwin" ]; then
  if [ "$ARCH" = "arm64" ]; then
    say "Instalando o app Neuro Harness"
    TMP="$(mktemp -d)"
    if [ "$MODE" = conta ]; then fetch_pkg "$SITE/api/app/mac" "$TMP/app.dmg"
    else gh release download "$VERSION" --repo "$REPO" --pattern '*arm64.dmg' --dir "$TMP" --clobber; fi
    DMG="$(ls "$TMP"/*.dmg | head -1)"
    MNT="$TMP/mnt"; mkdir -p "$MNT"
    hdiutil attach -nobrowse -quiet -mountpoint "$MNT" "$DMG"
    DEST="/Applications"; [ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }
    rm -rf "$DEST/Neuro Harness.app"
    cp -R "$MNT/Neuro Harness.app" "$DEST/"
    hdiutil detach -quiet "$MNT" || true
    xattr -dr com.apple.quarantine "$DEST/Neuro Harness.app" 2>/dev/null || true
    rm -rf "$TMP"
    ok "app em $DEST/Neuro Harness.app"
  else
    warn "o app desktop é só para Apple Silicon; neste Mac use o painel no navegador (neuro-harness open)"
  fi
fi

# ---------------------------------------------------------------- 5. pronto
if [ "$OPEN" = 1 ]; then
  say "Subindo o Neuro Harness"
  node "$SRC/lib/cli.js" start
  if [ "$WITH_APP" = 1 ] && [ "$OS" = "Darwin" ] && [ -d "/Applications/Neuro Harness.app" -o -d "$HOME/Applications/Neuro Harness.app" ]; then
    open -a "Neuro Harness" 2>/dev/null || node "$SRC/lib/cli.js" open
  else
    node "$SRC/lib/cli.js" open >/dev/null 2>&1 || true
  fi
fi

if [ "$ONLY_CLAUDE" = 1 ]; then
  cat <<EOF

${G}${B}Especialistas do Neuro Harness instalados no Claude Code.${X}
  Abra uma sessão nova do Claude Code e comece com /neuro-harness:comecar
  neuro-harness claude status     versões dos plugins
  neuro-harness claude instalar   atualiza depois de uma versão nova
${D}Abra um terminal novo para usar o comando neuro-harness.${X}
EOF
  exit 0
fi
CC_HINT=""
if [ "$CLAUDE" = 0 ] && command -v claude >/dev/null 2>&1; then
  CC_HINT="  neuro-harness claude instalar   leva os especialistas para o Claude Code (o Claude Code está neste computador)"
fi

cat <<EOF

${G}${B}Neuro Harness instalado.${X}
  neuro-harness status      estado e endereço do painel
  neuro-harness open        abre o painel no navegador
  neuro-harness doctor      confere tudo
  neuro-harness setup       atualiza depois de uma versão nova
  neuro-harness conta       mostra a conta conectada a este computador
${CC_HINT}
${D}Abra um terminal novo para usar o comando neuro-harness.${X}
EOF
