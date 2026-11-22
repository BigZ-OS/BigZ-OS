# Plano de infraestrutura BigZ OS

Pesquisa consultada em 21/11/2026. Limites de planos gratuitos podem mudar; confirmar novamente antes de produção. Nunca armazenar ISO/imagens/binários Microsoft: releases contêm apenas scripts/ferramentas BigZ, checksums e instruções para ISO oficial do usuário.

## Arquitetura recomendada

**Principal: Cloudflare Pages (site estático) + Workers + D1 (SQLite gerenciado).** Site público e catálogo da toolbox como JSON versionado/estático; Worker recebe telemetria estritamente opt-in com agregação mínima e endpoint de contador; D1 armazena eventos agregados e catálogo dinâmico somente se necessário. Workers Free tem 100 mil requisições/dia; D1 Free tem 5 milhões de linhas lidas/dia, 100 mil escritas/dia, 5 GB totais, até 10 DBs e 500 MB por DB; ao exceder os limites diários consultas falham até reset UTC. Fontes: [Workers limits](https://developers.cloudflare.com/workers/platform/limits/), [D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/), [D1 limits](https://developers.cloudflare.com/d1/platform/limits/). Datas consultadas: 21/11/2026.

**Reserva: GitHub Pages** para site estático/catalogo sem API/telemetria; limita site publicado a 1 GB, banda soft 100 GB/mês, builds soft 10/h; releases GitHub para downloads. Fonte: [GitHub Pages limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits). GitHub Free exibe 2.000 min Actions/mês, público gratuito; [preços](https://github.com/pricing).

| Serviço | Avaliação do nível grátis (21/11/2026) | Uso indicado |
|---|---|---|
| Cloudflare Pages/Workers | Pages estático; Workers 100k req/dia (fonte acima) | Principal, API pequena e catálogo |
| GitHub Pages | 1 GB publicado, soft 100 GB/mês | Reserva estática |
| Netlify | Limites/creditos dependem do plano atual; validar [pricing](https://www.netlify.com/pricing/) antes de adoção | Alternativa estática |
| Render | Serviços free podem suspender após inatividade e têm limites; [pricing](https://render.com/pricing) | Evitar API sempre disponível |
| Koyeb | Free instance sujeita a limites/pausa; [pricing](https://www.koyeb.com/pricing) | Não essencial |
| Fly.io | Não presumir allowance grátis; [pricing](https://fly.io/docs/about/pricing/) | Não recomendar como grátis permanente |
| Oracle Cloud Free Tier | Always Free condicionado a capacidade/região e conta; [pricing](https://www.oracle.com/cloud/free/) | Reserva operacional, exige administração |

SQL: **D1** é encaixe mais simples com Workers; SQLite gerenciado, limites explícitos acima. Alternativas: [Turso](https://turso.tech/pricing), [Neon](https://neon.tech/pricing), [Aiven](https://aiven.io/pricing), [TiDB](https://www.pingcap.com/tidb-serverless/), [CockroachDB](https://www.cockroachlabs.com/pricing/). Limites de free tier dessas ofertas não transcritos por não verificados diretamente nesta pesquisa; confirme os limites oficiais antes de selecionar. Não recomendar dependência em plano que possa suspender serviço crítico.

Telemetria deve ser desligada por padrão, exigir consentimento granular, evitar identificadores/IP persistentes e documentar retenção; contador não deve expor dados pessoais. Releases no GitHub Releases, evitando servir ISOs.

## GitHub e repositório

Repositório público criado: [BigZ-OS/BigZ-OS](https://github.com/BigZ-OS/BigZ-OS). O remoto `origin` está configurado; push permanece bloqueado até revisão de Auron e aprovação do usuário. Trunk principal `main`; branches curtas `feat/*`, `fix/*`, `docs/*`, `release/*`; PR obrigatório, checks verdes e revisão por CODEOWNERS. Proteger `main`: bloquear force-push/deleção, exigir PR e checks; regras avançadas podem depender do plano/organização.

Templates `.github/ISSUE_TEMPLATE/bug_report.yml`, `feature_request.yml`, `config.yml`; `.github/PULL_REQUEST_TEMPLATE.md`; CONTRIBUTING com checklist legal/segurança. Actions: PSScriptAnalyzer em PR/push main; validação Markdown/JSON; release manual via tag `v*`, gerar SHA256SUMS dos artefatos próprios, anexar checksums e notas; permissões mínimas `contents: read`, publicação isolada com `contents: write` apenas no workflow de release, aprovação de ambiente. Sem publicar ISO ou binários Microsoft. Actions públicas: minutos gratuitos segundo [GitHub pricing](https://github.com/pricing).

## Backup Google Drive

| Método | Vantagem | Limite/risco |
|---|---|---|
| Google Drive para desktop | Sincronização simples local | Exige instalação/login; sincronização não é backup versionado |
| rclone | Agendável, criptografia opcional, logs | Instalação e OAuth/escopo Drive precisam autorização |
| GitHub Action | Automatiza cópia de código | Segredo OAuth/service account e permissões; dependência cloud; não inclui arquivos ignorados |

O rclone está configurado e o backup semanal para o Google Drive roda aos domingos às 20h; script: `infra/backup-drive.ps1`. O client_id compartilhado do Google Drive será desativado: seguir `infra/03-client-id-rclone.md` para criar credencial própria gratuita. Confirme retenção e teste restauração periodicamente.

## Preparação local concluída

`.gitignore` exclui `builder_refs/`, ISOs, WIM/ESD/VHD/VHDX, segredos, `.env`, chaves e artefatos temporários. `.gitattributes` padroniza texto em LF e trata scripts/docs. Repositório público remoto `BigZ-OS/BigZ-OS` existe e `origin` está configurado; sem push até aprovação explícita. O `.docx` original está excluído do Git. Licença aprovada: GPL-3.0-or-later para código e CC BY-SA 4.0 para assets.

## Aprovações via Auron antes de ações externas

1. Revisar conteúdo e autorizar push inicial para o repositório público existente.
2. Criar/autorizar conta e projeto Cloudflare, publicar site/Worker e criar D1 (confirmar termos e limites).
3. Client ID próprio do rclone: usuário criar no Google Cloud Console e concluir consentimento OAuth; backup semanal já configurado.
4. Aprovar publicação de releases e ativação de telemetria opt-in.

