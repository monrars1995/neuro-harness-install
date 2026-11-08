# Instalador do Neuro Harness

Este repositório público guarda só os **scripts de instalação** do [Neuro Harness](https://github.com/monrars1995/neuro-harness), o estúdio de agentes de IA para pós-produção de vídeo, em português.

**Os scripts não contêm segredos.** O Neuro Harness e os plugins ficam em repositórios privados. O instalador faz o login no GitHub e baixa o resto com a sua conta, então ela precisa ter acesso.

## macOS e Linux

```bash
curl -fsSL https://raw.githubusercontent.com/monrars1995/neuro-harness-install/main/install.sh | bash
```

## Windows 10/11 (PowerShell)

```powershell
irm https://raw.githubusercontent.com/monrars1995/neuro-harness-install/main/install.ps1 | iex
```

## O que o instalador faz

1. **Dependências:** instala o que faltar entre Node.js 22+, git, Python 3.10+, FFmpeg e GitHub CLI.
   - **macOS:** usa o Homebrew, e instala o Homebrew se faltar.
   - **Linux:** usa apt, dnf ou pacman.
   - **Windows:** usa o winget.
2. **Login no GitHub:** pelo navegador (`gh auth login --web`), deixando o `git` pronto para os repositórios privados.
3. **Neuro Harness:** baixa a última versão (Release) para `~/.neuro-harness/src`. O comando `neuro-harness` fica no seu PATH.
4. **`neuro-harness setup`:** instala, numa pasta só dele (`~/.neuro-harness`):
   - o DeepSeek Harness, numa versão fixa;
   - o motor **neuro-mv-edit** e o plugin **neuro-ads-manager**;
   - a marca e o pt-BR;
   - os plugins oficiais já ativos (equipes de agentes, permissão Auto, busca em sessões, terminal persistente e títulos de sessão).
5. **Chaves de API:** importa as que você já tem no Hermes e no OpenCode, testando cada uma.
6. **App desktop:** instala o app (macOS Apple Silicon e Windows).
7. **Abertura:** sobe o Neuro Harness e abre o painel.

## Opções

| macOS/Linux (`… \| bash -s -- <opção>`) | Windows (`-Opção`) | Para quê |
|---|---|---|
| `--sem-app` | `-SemApp` | Não instala o app desktop |
| `--versao vX.Y.Z` | `-Versao vX.Y.Z` | Instala uma versão específica |
| `--sem-credenciais` | `-SemCredenciais` | Não importa chaves de API |
| `--sem-abrir` | `-SemAbrir` | Não sobe nem abre o painel no fim |

**Exemplos com opções:**

```bash
curl -fsSL https://raw.githubusercontent.com/monrars1995/neuro-harness-install/main/install.sh | bash -s -- --sem-app
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/monrars1995/neuro-harness-install/main/install.ps1))) -SemApp
```

**Atualizar:** rode o mesmo comando de novo. O instalador é idempotente e só refaz o que mudou.

---

O Neuro Harness é construído sobre o [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (MIT, © DeepSeek). Ele não é um produto oficial da DeepSeek.

**Autor:** Ramon Ribeiro
- GitHub [@monrars1995](https://github.com/monrars1995)
- Instagram [@monrars](https://instagram.com/monrars) e [@goldneuron.io](https://instagram.com/goldneuron.io)

Licença MIT.
