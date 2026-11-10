---
name: muse-code
description: Delega uma tarefa ao Muse Code, o agente de código da Meta, pela assinatura do usuário, chamando o CLI oficial `muse exec`. Use quando o usuário pedir para usar o Muse Code, a assinatura da Meta ou os modelos Muse.
whenToUse: O usuário pede "use o Muse Code", "faça pela assinatura da Meta", "rode no muse" ou quer um modelo Muse (muse-wonder, muse-spark) sem gastar a chave de API.
---

# Muse Code pela assinatura

A assinatura do Muse Code só vale dentro do cliente oficial da Meta. Por isso este agente **não** chama os modelos Muse direto: ele entrega a tarefa ao CLI `muse`, que já está logado com a conta do usuário.

## Antes de usar

1. Confira que o CLI existe e está logado: `muse --version` e `muse usage`. O `usage` mostra o plano e quanto da janela já foi usada.
2. Se não estiver logado, peça ao usuário para rodar `muse login` no terminal dele. O login é feito no navegador; não tente fazer por ele.

## Como delegar

Rode sempre **sem** `META_API_KEY` no ambiente. Uma chave de API tem prioridade sobre o login e cobraria por uso em vez da assinatura.

```bash
env -u META_API_KEY muse exec --workspace "<pasta do projeto>" --reasoning-effort high "<tarefa completa, com o contexto necessário>"
```

- **Tarefa longa:** escreva o pedido num arquivo e use `--prompt-file <arquivo>`.
- **Para ler o resultado de forma estruturada:** acrescente `--json` (eventos JSONL na saída).
- **Modelo:** `--model muse-wonder-1.0` ou `--model muse-spark-1.3`; sem `--model`, vale o padrão do Muse Code.
- **Imagens:** `--image <arquivo>` (pode repetir).
- **Isolar mudanças:** `-w create` cria uma worktree git para a sessão.
- **Tarefas demoradas:** rode no terminal persistente, em segundo plano, e acompanhe a saída.

## Depois

- Mostre ao usuário o resumo do que o Muse Code fez e os arquivos alterados (`git status`/`git diff` na pasta).
- Se a resposta disser que a cota da janela acabou, avise e mostre `muse usage`; não troque sozinho para uma chave paga.
