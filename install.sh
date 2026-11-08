#!/usr/bin/env bash
# Instalador do Neuro Harness para macOS e Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/monrars1995/neuro-harness-install/main/install.sh | bash
#
# Opções (depois de "bash -s --"):
#   --sem-app           não baixa o app desktop (macOS)
#   --versao vX.Y.Z     instala uma versão específica (padrão: a última Release)
#   --sem-credenciais   não importa chaves de API do Hermes e do OpenCode
#   --sem-abrir         não sobe nem abre o Neuro Harness no fim
#
# Este script é público e não contém segredos. Os repositórios do Neuro Harness são privados:
# o script faz o login no GitHub (gh) e usa as suas credenciais para baixar o resto.
set -euo pipefail

REPO="monrars1995/neuro-harness"
NH_HOME="${NEURO_HARNESS_HOME:-$HOME/.neuro-harness}"
SRC="$NH_HOME/src"
WITH_APP=1; VERSION=""; CREDS=1; OPEN=1
while [ $# -gt 0 ]; do
  case "$1" in
    --sem-app) WITH_APP=0 ;;
    --versao) VERSION="${2:-}"; shift ;;
    --sem-credenciais) CREDS=0 ;;
    --sem-abrir) OPEN=0 ;;
    -h|--help) sed -n '2,16p' "$0" 2>/dev/null || true; exit 0 ;;
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
  has gh || pkgs+=(gh)
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
    if ! has gh; then
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
    has gh || asroot dnf install -y gh
  elif has pacman; then
    say "Instalando dependências (pacman; o sudo pode pedir a sua senha)"
    asroot pacman -Sy --needed --noconfirm git python ffmpeg nodejs npm github-cli
  else
    die "Gerenciador de pacotes não suportado. Instale à mão: Node.js 22+, git, Python 3.10+, FFmpeg e GitHub CLI."
  fi
}

say "Conferindo dependências"
case "$OS" in
  Darwin) deps_mac ;;
  Linux) deps_linux ;;
  *) die "Sistema não suportado: $OS (no Windows, use install.ps1)" ;;
esac
node_ok || die "Node.js 22+ não encontrado."
for c in git ffmpeg gh; do has "$c" || die "$c não encontrado."; done
python_ok || die "Python 3.10+ não encontrado."
ok "Node $(node -v) · git · Python · FFmpeg · GitHub CLI"

# ---------------------------------------------------------------- 2. login no GitHub
say "Login no GitHub (repositórios privados)"
if ! gh auth status >/dev/null 2>&1; then
  printf '  %sO navegador vai abrir para você entrar no GitHub com a conta que tem acesso ao Neuro Harness.%s\n' "$D" "$X"
  tty gh auth login --web --git-protocol https --hostname github.com
fi
gh auth setup-git >/dev/null 2>&1 || true
gh api "repos/$REPO" --jq .full_name >/dev/null 2>&1 || die "Sua conta do GitHub não tem acesso a $REPO. Peça acesso ao dono do repositório."
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

say "Instalando o Harness, o motor, o perfil e os plugins (a primeira vez baixa ~550 MB)"
node "$SRC/lib/cli.js" setup

if [ "$CREDS" = 1 ] && { [ -f "$HOME/.hermes/.env" ] || [ -f "$HOME/.local/share/opencode/auth.json" ]; }; then
  say "Importando chaves de API do Hermes e do OpenCode"
  node "$SRC/lib/cli.js" credenciais || warn "não foi possível importar as chaves agora (rode: neuro-harness credenciais)"
fi

# ---------------------------------------------------------------- 4. app desktop (macOS Apple Silicon)
if [ "$WITH_APP" = 1 ] && [ "$OS" = "Darwin" ]; then
  if [ "$ARCH" = "arm64" ]; then
    say "Instalando o app Neuro Harness"
    TMP="$(mktemp -d)"
    gh release download "$VERSION" --repo "$REPO" --pattern '*arm64.dmg' --dir "$TMP" --clobber
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

cat <<EOF

${G}${B}Neuro Harness instalado.${X}
  neuro-harness status      estado e endereço do painel
  neuro-harness open        abre o painel no navegador
  neuro-harness doctor      confere tudo
  neuro-harness setup       atualiza depois de uma versão nova
${D}Construído sobre o DeepSeek Harness. Abra um terminal novo para usar o comando neuro-harness.${X}
EOF
