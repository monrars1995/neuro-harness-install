---
description: Instala (ou atualiza) os especialistas do Neuro Harness neste Claude Code — edição de vídeo, gestão de tráfego e copy — pela sua conta Neuro
---

Instale os especialistas do Neuro Harness no Claude Code.

1. Confira os requisitos: `node --version` (18 ou mais novo) e `command -v claude`. O instalador cuida do resto (ffmpeg, Python, git) e pode pedir a senha do computador para isso; nesse caso, peça ao usuário para rodar o comando do passo 2 no terminal dele.
2. Rode, em segundo plano (ele espera a confirmação no navegador): `npx -y @oneuros/harness@0.5.1 claude`.
   - O navegador abre para o usuário entrar na conta Neuro e confirmar este computador. Diga isso a ele e espere.
   - Conta sem aprovação: o instalador avisa; o pedido de acesso é feito em https://harness.neuros.my/acesso.
3. No fim, rode `npx -y @oneuros/harness@0.5.1 claude status` e mostre a versão de cada especialista.
4. Diga ao usuário para abrir uma sessão nova do Claude Code (ou rodar `/reload-plugins`) e começar com `/neuro-harness:comecar`.

Nunca peça a chave de instalação (`nh_…`) no chat: ela é gravada pelo próprio instalador.
