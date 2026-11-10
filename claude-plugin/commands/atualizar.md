---
description: Atualiza os especialistas do Neuro Harness no Claude Code (neuro-mv-edit e neuro-ads-manager) para as versões fixadas da distribuição
---

Atualize os plugins do Neuro Harness.

1. Rode `npx -y @oneuros/harness@0.6.0 claude` (baixa as versões novas pela conta Neuro e atualiza os especialistas no Claude Code). Com o Neuro Harness completo instalado, `neuro-harness setup && neuro-harness claude instalar` faz o mesmo.
2. Sem o `neuro-harness` (marketplace pelo GitHub): rode `claude plugin marketplace update neuro-harness` e, para cada plugin instalado dele, `claude plugin update <nome>@neuro-harness`.
3. Mostre a versão de cada plugin antes e depois (`claude plugin list --json`) e avise que os comandos novos aparecem depois de reiniciar a sessão (`/exit` e abrir de novo) ou de rodar `/reload-plugins`.
