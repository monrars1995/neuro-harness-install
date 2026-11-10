# Neuro Harness · instalador

Instalador público do [Neuro Harness](https://harness.neuros.my): especialistas de IA em português para **edição de vídeo** (exportação em 4K, 1440p ou 1080p sem perder qualidade), **gestão de tráfego** na Meta e **copy** com as regras de cada segmento. Funcionam no app, no painel do navegador e no **Claude Code**.

Este repositório tem os scripts de instalação, o pacote npm `@oneuros/harness` e o plugin central do Claude Code. O código do Harness e dos especialistas também é aberto ([oneuros-harness](https://github.com/monrars1995/oneuros-harness), [oneuros-mv-edit](https://github.com/monrars1995/oneuros-mv-edit), [oneuros-ads-manager](https://github.com/monrars1995/oneuros-ads-manager)); a instalação dos agentes passa pela sua conta Neuro, depois da aprovação ([pedir acesso](https://harness.neuros.my/acesso)). Nada aqui contém segredos.

## Instalar

| Onde | Comando |
|---|---|
| macOS e Linux | `curl -fsSL https://harness.neuros.my/install.sh \| bash` |
| Windows 10/11 (PowerShell) | `irm https://harness.neuros.my/install.ps1 \| iex` |
| npm (qualquer sistema com Node 18+) | `npx @oneuros/harness` |

### Só no Claude Code

| Onde | Comando |
|---|---|
| npm | `npx @oneuros/harness claude` |
| macOS e Linux | `curl -fsSL https://harness.neuros.my/install.sh \| bash -s -- --apenas-claude-code` |
| Windows | `& ([scriptblock]::Create((irm https://harness.neuros.my/install.ps1))) -ApenasClaudeCode` |
| Dentro do Claude Code | `/plugin marketplace add monrars1995/neuro-harness-install`, depois `/plugin install neuro-harness@neuros` e `/neuro-harness:instalar` |

Depois, abra uma sessão nova do Claude Code e comece com `/neuro-harness:comecar`.

O endereço `harness.neuros.my` serve os scripts deste repositório. Se ele estiver fora do ar, use `https://raw.githubusercontent.com/monrars1995/neuro-harness-install/main/` no lugar de `https://harness.neuros.my/`.

## O que o instalador faz

1. **Dependências:** instala o que faltar entre Node.js 22+, git, Python 3.10+ e FFmpeg (Homebrew no macOS, apt/dnf/pacman no Linux, winget no Windows).
2. **Conta Neuro:** abre o navegador para você confirmar este computador e grava uma chave pessoal de instalação. A conta precisa estar aprovada.
3. **Neuro Harness:** baixa a última versão para `~/.neuro-harness` e põe o comando `neuro-harness` no PATH.
4. **Especialistas:** instala os especialistas de vídeo e de tráfego/copy nas versões da distribuição.
5. **Claude Code** (com `--claude-code` ou `--apenas-claude-code`): registra o marketplace local `neuro-harness` e instala os especialistas como plugins.
6. **App desktop** (macOS Apple Silicon e Windows) e abertura do painel, fora do modo `--apenas-claude-code`.

**Atualizar:** rode o mesmo comando de novo. O instalador só refaz o que mudou.

## Opções

| macOS/Linux e npm | Windows | Para quê |
|---|---|---|
| `--claude-code` | `-ClaudeCode` | Também instala os especialistas no Claude Code |
| `--apenas-claude-code` | `-ApenasClaudeCode` | Só os especialistas no Claude Code, sem app e sem painel |
| `--sem-app` | `-SemApp` | Sem o app desktop |
| `--sem-credenciais` | `-SemCredenciais` | Não importa chaves de API de outras ferramentas |
| `--sem-abrir` | `-SemAbrir` | Não abre o painel no fim |
| `--versao vX.Y.Z` | `-Versao vX.Y.Z` | Uma versão específica |
| `--chave nh_…` | `-Chave nh_…` | Usa a chave de instalação da sua conta Neuro |
| `--github` | `-GitHub` | Desenvolvimento: clona os repositórios públicos, sem a conta Neuro |

No `curl … | bash`, passe as opções depois de `bash -s --`. No npm: `npx @oneuros/harness --sem-app`.

## Com o Neuro Harness instalado

`npx @oneuros/harness <comando>` repassa ao CLI instalado: `status`, `doctor`, `claude status`, `conta`, `entrar` e os demais. Referência completa em [h-docs.neuros.my](https://h-docs.neuros.my/referencia/cli).

## Conteúdo deste repositório

| Caminho | O que é |
|---|---|
| `install.sh`, `install.ps1` | Os instaladores |
| `bin/neuro-harness.js` | O comando do pacote npm `@oneuros/harness` |
| `claude-plugin/` | Plugin central do Claude Code: `/neuro-harness:instalar`, `comecar`, `verificar`, `atualizar` e a skill `muse-code` |
| `.claude-plugin/marketplace.json` | Marketplace público `neuros`, com o plugin central |
| `.github/workflows/npm.yml` | Publica no npm a cada tag `vX.Y.Z` (segredo `NPM_TOKEN`) |

---

**Autor:** Ramon Ribeiro · GitHub [@monrars1995](https://github.com/monrars1995) · Instagram [@monrars](https://instagram.com/monrars). Um produto [@goldneuron.io](https://instagram.com/goldneuron.io).

Licença MIT.
