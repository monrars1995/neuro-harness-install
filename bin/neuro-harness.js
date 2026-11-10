#!/usr/bin/env node
'use strict'
/**
 * @neuros/harness — o instalador público do Neuro Harness pelo npm.
 *
 *   npx @neuros/harness                     instala o Neuro Harness (o mesmo que o comando de uma linha)
 *   npx @neuros/harness claude              só os especialistas no Claude Code (sem app e sem painel)
 *   npx @neuros/harness <comando>           com o Neuro Harness instalado, repassa ao CLI dele
 *                                           (status, doctor, claude status, entrar, conta...)
 *
 * Este pacote não traz os especialistas: eles são baixados pela sua conta Neuro, depois da aprovação.
 * Os scripts de instalação são os mesmos deste repositório público (install.sh e install.ps1).
 */
const fs = require('fs')
const os = require('os')
const path = require('path')
const { spawnSync } = require('child_process')

const PKG = require('../package.json')
const ROOT = path.resolve(__dirname, '..')
const IS_WIN = process.platform === 'win32'
const HOME = process.env.NEURO_HARNESS_HOME || path.join(os.homedir(), '.neuro-harness')
const CLI = path.join(HOME, 'src', 'lib', 'cli.js')

// opções do install.sh → parâmetros do install.ps1
const PS_FLAGS = {
  '--sem-app': '-SemApp', '--sem-credenciais': '-SemCredenciais', '--sem-abrir': '-SemAbrir', '--github': '-GitHub',
  '--claude-code': '-ClaudeCode', '--apenas-claude-code': '-ApenasClaudeCode', '--so-claude-code': '-ApenasClaudeCode',
  '--versao': '-Versao', '--chave': '-Chave',
}

function help() {
  console.log(`Neuro Harness ${PKG.version} · instalador (npm)

  npx @neuros/harness [opções]          instala ou atualiza o Neuro Harness
  npx @neuros/harness claude            só os especialistas no Claude Code
  npx @neuros/harness <comando>         repassa ao CLI instalado (status, doctor, claude status, conta...)

Opções do instalador:
  --claude-code          também instala os especialistas no Claude Code
  --apenas-claude-code   só os especialistas no Claude Code
  --sem-app              sem o app desktop
  --sem-credenciais      não importa chaves de API de outras ferramentas
  --sem-abrir            não abre o painel no fim
  --versao vX.Y.Z        uma versão específica
  --chave nh_…           usa a chave de instalação da sua conta Neuro

Site: https://harness.neuros.my · Documentação: https://h-docs.neuros.my`)
}

function runInstaller(args) {
  if (IS_WIN) {
    const ps = []
    for (let i = 0; i < args.length; i++) {
      const f = PS_FLAGS[args[i]]
      if (!f) { console.error(`opção desconhecida: ${args[i]}`); return 2 }
      ps.push(f)
      if (f === '-Versao' || f === '-Chave') ps.push(args[++i] || '')
    }
    const r = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(ROOT, 'install.ps1'), ...ps], { stdio: 'inherit' })
    return r.status === null ? 1 : r.status
  }
  const r = spawnSync('bash', [path.join(ROOT, 'install.sh'), ...args], { stdio: 'inherit' })
  return r.status === null ? 1 : r.status
}

function delegate(args) {
  if (!fs.existsSync(CLI)) {
    console.error(`O Neuro Harness não está instalado neste computador (${HOME}).\nInstale com: npx @neuros/harness   (ou só para o Claude Code: npx @neuros/harness claude)`)
    return 1
  }
  const r = spawnSync(process.execPath, [CLI, ...args], { stdio: 'inherit' })
  return r.status === null ? 1 : r.status
}

function main(argv) {
  const [cmd, ...rest] = argv
  if (cmd === 'help' || cmd === '--help' || cmd === '-h') { help(); return 0 }
  if (cmd === 'version' || cmd === '--version' || cmd === '-v') { console.log(PKG.version); return 0 }
  if (!cmd || cmd.startsWith('--') || cmd === 'instalar' || cmd === 'install') {
    return runInstaller(cmd && !cmd.startsWith('--') ? rest : argv)
  }
  if ((cmd === 'claude' || cmd === 'claude-code') && (!rest.length || rest[0] === 'instalar' || rest[0] === 'install' || rest[0].startsWith('--'))) {
    // instala ou atualiza o CLI e os especialistas no Claude Code (o instalador sabe pular o que já está em dia)
    const extra = rest.filter((a) => a.startsWith('--'))
    return runInstaller(['--apenas-claude-code', ...extra])
  }
  return delegate(argv)
}

process.exitCode = main(process.argv.slice(2))
