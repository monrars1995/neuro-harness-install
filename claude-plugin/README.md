# Neuro Harness para Claude Code

Especialistas de IA em português do Brasil para quem trabalha com conteúdo e anúncios: **edição de vídeo** do bruto à entrega (decupagem, legendas, cenas, som e exportação em 4K, 1440p ou 1080p sem perder a qualidade do original), **gestão de tráfego** na Meta (auditoria, plano, relatório e conferência da conversão) e **copy** de anúncios revisada pelas regras de cada segmento.

Este plugin é a porta de entrada. Ele instala e organiza os especialistas, que são liberados pela sua conta Neuro depois da aprovação ([pedir acesso](https://harness.neuros.my/acesso)).

## Comandos

| Comando | O que faz |
|---|---|
| `/neuro-harness:instalar` | Liga a sua conta Neuro e instala ou atualiza os especialistas neste Claude Code |
| `/neuro-harness:comecar` | Mostra os especialistas instalados e leva o seu pedido ao certo |
| `/neuro-harness:verificar` | Confere o ambiente de todos os especialistas e instala o que faltar |
| `/neuro-harness:atualizar` | Atualiza os especialistas para as versões mais novas |

Também traz a skill `muse-code`, que entrega uma tarefa ao CLI oficial do Muse Code (Meta) pela sua assinatura.

## Como funciona

O `/neuro-harness:instalar` roda o instalador público `@oneuros/harness` (npm), que abre o navegador para você confirmar este computador na sua conta, baixa os especialistas e os registra no Claude Code como plugins de um marketplace local. Nenhuma chave é pedida no chat.

Requisitos: Node.js 18 ou mais novo. O instalador cuida do FFmpeg, do Python e do git quando faltarem.

Site: [harness.neuros.my](https://harness.neuros.my) · Documentação: [h-docs.neuros.my](https://h-docs.neuros.my/guias/claude-code) · Licença MIT.
