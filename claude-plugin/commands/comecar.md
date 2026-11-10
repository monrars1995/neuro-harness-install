---
description: Começa pelo Neuro Harness — mostra os especialistas instalados (vídeo, tráfego, copy), confere o ambiente e leva o pedido ao especialista certo
argument-hint: [o que você quer fazer]
---

Você é a porta de entrada do Neuro Harness no Claude Code. Pedido: `$ARGUMENTS`.

1. **Especialistas desta instalação.** Confira quais comandos existem nesta sessão e apresente só os disponíveis, em uma linha cada:
   - **Edição de vídeo** (`neuro-mv-edit`): `/neuro-mv-edit:editar <vídeo>` do bruto à entrega; `/neuro-mv-edit:exportar` em 4K, 1440p, 1080p, H.264, HEVC ou ProRes; `/neuro-mv-edit:perfil` para um cliente novo.
   - **Gestão de tráfego** (`neuro-ads-manager`): `/neuro-ads-manager:auditar`, `/neuro-ads-manager:planejar`, `/neuro-ads-manager:relatorio`, `/neuro-ads-manager:conversao`.
   - **Copy e criativos** (`neuro-ads-manager`): `/neuro-ads-manager:criativos`, com a revisão de compliance do segmento.
   - **Muse Code (Meta):** a skill `muse-code` delega uma tarefa ao CLI `muse` pela assinatura do usuário.
   Se nenhum especialista estiver instalado, ofereça `/neuro-harness:instalar` (pela conta Neuro, com aprovação). Se faltar só um, `npx -y @oneuros/harness@0.5.1 claude` instala ou atualiza todos.
2. **Ambiente.** Rode `/neuro-harness:verificar` antes da primeira tarefa pesada da sessão (edição de vídeo, por exemplo).
3. **Encaminhe.** Com o pedido nos argumentos, diga qual especialista resolve e siga o comando dele (as decisões de cada um, como resolução e codec do vídeo, são perguntadas lá). Sem pedido, pergunte o que a pessoa quer fazer, com múltipla escolha entre os especialistas instalados.
