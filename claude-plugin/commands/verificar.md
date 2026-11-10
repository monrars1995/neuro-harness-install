---
description: Verifica o ambiente de todos os especialistas do Neuro Harness (vídeo, tráfego, Muse Code), instala o que dá para instalar sozinho e diz o que depende de você
argument-hint: [--resolucao 4k,1080p] [--codec h264|hevc|prores] [--motor remotion|hyperframes] [--video <fonte>]
---

Verifique o ambiente do Neuro Harness. Argumentos: `$ARGUMENTS`.

1. **Edição de vídeo.** Se o comando `neuro-mv-edit` existir (`command -v neuro-mv-edit`), rode `neuro-mv-edit verificar --corrigir` com as decisões que vierem nos argumentos (`--motor`, `--resolucao`, `--codec`, `--video`). Sem decisões e com uma edição em vista, use `/neuro-mv-edit:verificar`, que pergunta antes.
2. **Gestão de tráfego.** Se `neuro-ads-manager` existir, rode `neuro-ads-manager status`. Nunca abra nem mostre arquivos `.env`; o token da Meta é configurado pelo próprio usuário.
3. **MCPs da sessão.** Confira se as ferramentas `mcp__elevenlabs__*` (som do vídeo) estão disponíveis. Se não, peça ao usuário para autorizar o ElevenLabs em `/mcp`.
4. **Muse Code.** Se o usuário usa a Meta pela assinatura: `muse --version` e `muse usage`. Sem login, peça ao usuário para rodar `muse login` no terminal dele.
5. **Versões.** Rode `npx -y @oneuros/harness@0.6.0 claude status` para ver a versão de cada especialista e se há atualização.
6. **Resumo:** o que estava faltando, o que foi instalado agora, o que depende do usuário (com o comando exato) e se tudo está pronto.
