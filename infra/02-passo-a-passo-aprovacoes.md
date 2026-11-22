# Aprovações pendentes: passos e escopo

Este documento prepara decisões para o usuário via Auron. Nenhuma conta foi acessada, instalação feita, nem mudança remota executada. Data: 21/11/2026.

## 1. GitHub: repositório público e push inicial

1. Usuário confirma organização/conta mantenedora (`BigZ-OS` sugerida), nome `BigZ-OS` e visibilidade pública.
2. Usuário/Auron cria a organização, configura ao menos dois mantenedores e confirma e-mail público de segurança. Nome de organização é sujeito à disponibilidade.
3. Revisar conteúdo local e licença aprovada; confirmar que não há ISOs, WIMs, binários Microsoft ou segredos no commit.
4. Autorizar explicitamente criação do repositório remoto e push do histórico/conteúdo local. Sem essa autorização, repo permanece local.
5. Após criação, habilitar proteção de `main`: PR obrigatório, checks `lint`, force-push e deleção bloqueados; revisar CODEOWNERS placeholder e substituir por equipe real. Aplicabilidade de regras pode depender do plano.

## 2. Cloudflare (pode esperar F4)

1. Usuário autoriza criar/usar conta Cloudflare e fornece login diretamente no site oficial; agente não pede senha no chat.
2. Autorizar criação do projeto Pages conectado ao repositório, deploy de site estático e Worker para API mínima.
3. Autorizar criação de banco D1 e confirmar retenção e política de telemetria: opt-in explícito, mínimo de dados e desligada por padrão.
4. Confirmar domínio (se houver) e publicação pública. Limites Free podem interromper consultas no excedente; monitorar quotas antes do lançamento.
5. Plano reserva: ativar GitHub Pages sem backend caso Workers/D1 indisponíveis.

## 3. rclone + Google Drive

1. Usuário autoriza instalar rclone no computador. Alternativa: Google Drive para desktop, também exige aprovação de instalação/login.
2. Obter rclone somente da distribuição oficial e concluir OAuth no navegador do usuário, concedendo escopo Drive necessário para pasta dedicada.
3. Usuário escolhe pasta de destino, frequência semanal e retenção. Proposta: espelho de fontes/docs, excluir caches, builder_refs, ISOs/WIMs e segredos; manter versões recuperáveis.
4. Autorizar configuração de tarefa agendada local e execução do primeiro backup. Confirmar log sem conteúdo secreto e testar restauração de amostra.
5. OAuth/token fica no perfil local protegido; nunca no GitHub, workflow ou arquivo versionado. Revogação pelo usuário nas permissões da conta Google.

## Itens ainda dependentes

- Aprovar GPL-3.0-or-later para código e CC BY-SA 4.0 para assets (plano consolidado).
- Definir e-mail público de segurança.
- Revisão jurídica antes do lançamento público.
- Escolher GitHub org/repo; confirmar nomes disponíveis.
- Nenhuma aprovação acima foi presumida por este guia.
