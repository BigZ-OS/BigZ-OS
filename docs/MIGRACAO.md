# Migrar o BigZ OS para outro computador

Checklist para levar o projeto, o time de agentes OpenBot e o laboratório para um PC novo.
Requisitos do PC novo: **Windows 11 Pro** (o Hyper-V exige), de preferência **16 GB de RAM ou mais**, cerca de 60 GB livres para o laboratório.

## 1. No PC atual (antes de exportar)
- [ ] Todo o trabalho com commit e enviado ao GitHub (`git status` limpo, `git log origin/main..main` vazio).
- [ ] Backup final no Google Drive: `powershell -NoProfile -ExecutionPolicy Bypass -File "C:\DEV\PROJETOS_MDEV\BigZ OS\infra\backup-drive.ps1"`.
- [ ] Nenhuma VM do laboratório ligada e nenhum build em andamento.
- [ ] Exportar o servidor OpenBot: na lista de servidores à esquerda, clique com o botão direito no servidor → **Server settings** → **Transfer** → exportar o `.zip`. Isso leva os agentes, as skills, as rotinas, as memórias e os arquivos de trabalho. Só o dono ou um admin do servidor pode exportar.

Não precisa copiar: `C:\DEV\BigZ-Lab` (ISOs e builds, que são baixados e gerados de novo) nem as ferramentas instaladas. **Logins não vão no `.zip`**: GitHub CLI, rclone/Google Drive e o navegador do OpenBot são refeitos no PC novo.

## 2. No PC novo
1. Instale o OpenBot, entre na mesma conta e importe o `.zip` em **Server settings** → **Transfer**.
2. Em um PowerShell **normal**, instale o Git e o GitHub CLI e clone o repositório **no mesmo caminho**. Os agentes e a rotina de backup usam este caminho:
   ```powershell
   winget install --id Git.Git -e
   winget install --id GitHub.cli -e
   # feche e reabra o PowerShell para atualizar o PATH
   gh auth login --hostname github.com --git-protocol https --web --scopes workflow
   gh auth setup-git
   New-Item -ItemType Directory -Force 'C:\DEV\PROJETOS_MDEV' | Out-Null
   gh repo clone BigZ-OS/BigZ-OS 'C:\DEV\PROJETOS_MDEV\BigZ OS'
   cd 'C:\DEV\PROJETOS_MDEV\BigZ OS'
   git config user.name 'BigZ'
   git config user.email '326611709+themarcosmail-bot@users.noreply.github.com'
   ```
3. Prepare o laboratório com **um único UAC**. O script instala rclone, Windows ADK, Pester 5.7.1, PSScriptAnalyzer, ativa o Hyper-V e cria `C:\DEV\BigZ-Lab`:
   ```powershell
   Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','C:\DEV\PROJETOS_MDEV\BigZ OS\infra\lab\Setup-BigZLab.ps1'
   ```
   Resultado em `C:\DEV\BigZ-Lab\logs\setup-status.json`. **Reinicie o PC** se `restartNeeded` vier `true`.
4. Reconecte o Google Drive. O rclone só acessa os arquivos que ele mesmo criou:
   ```powershell
   rclone config create gdrive drive scope=drive.file
   rclone lsd gdrive:BigZ-OS-Backup
   ```
   Aviso: o client_id compartilhado do rclone para o Google Drive está sendo desativado. Veja em `infra/` o guia para criar um client_id próprio, que é gratuito.
5. Recupere o documento original (fica fora do repositório público):
   ```powershell
   rclone copy "gdrive:BigZ-OS-Backup/atual/IDEIA DO PROJETO QUE PODE MUDAR A MINHA VIDA.docx" 'C:\DEV\PROJETOS_MDEV\BigZ OS'
   ```
6. No navegador do OpenBot, entre de novo no GitHub (conta themarcosmail-bot), se for preciso.

## 3. Conferir
```powershell
cd 'C:\DEV\PROJETOS_MDEV\BigZ OS'
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester -Path tests/unit, tests/integration      # todos devem passar
gh auth status
rclone listremotes                                      # deve listar gdrive:
```
- [ ] A rotina "Backup semanal BigZ OS → Google Drive" aparece ativa no OpenBot (domingo, 20h).
- [ ] Os 8 agentes da seção "BigZ OS" respondem.

## 4. Desativar o PC antigo (opcional, depois de conferir)
- Pause ou apague a rotina de backup no OpenBot do PC antigo, para não haver dois backups.
- `gh auth logout` e remova `%APPDATA%\rclone\rclone.conf` no PC antigo.
- Para recuperar espaço, apague `C:\DEV\BigZ-Lab` (ISOs e builds, cerca de 23 GB).

## 5. Laboratório no PC novo
- Coloque as ISOs oficiais em `C:\DEV\BigZ-Lab\iso`: a Enterprise Evaluation para testes, ou a Home/Pro para builds reais. Deixe só uma ISO na pasta por build.
- Build: `infra/lab/Invoke-BigZLabBuild.ps1` (use `-TestOnly` com a Evaluation). Status em `C:\DEV\BigZ-Lab\logs\build-status.json`.
- VM e testes P0: veja `docs/qa/sequencia-iso-testonly-balanced.md` e `tests/hyperv/README.md`.
