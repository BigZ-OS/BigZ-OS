# ADR-009 — Infraestrutura: Cloudflare Pages + Workers + D1, GitHub Pages de reserva, GitHub Releases

- **Status:** Aceita (a execução depende das aprovações do usuário: contas GitHub/Cloudflare) · **Data:** 2026-11-21 · **Dono:** Cloud · **Revisores:** Beatrix, Auron

## Contexto
A Carta exige hospedagem e banco SQL gratuitos e proíbe Supabase e Vercel. Os downloads precisam ser verificáveis (checksums/atestado) e nunca conter binários da Microsoft (ADR-001). Telemetria é um tema sensível para o público.

## Decisão
- **Site:** Cloudflare Pages (estático) como principal; **GitHub Pages** como reserva estática.
- **API pequena/contador:** Cloudflare Workers; **banco:** Cloudflare D1 (SQLite gerenciado), só se for necessário.
- **Downloads:** apenas **GitHub Releases** do repositório oficial, com `SHA256SUMS` e atestado de proveniência. O site só aponta para lá.
- **Telemetria desligada por padrão:** consentimento granular, sem identificadores ou IP persistentes, retenção documentada.
- **Proibidos:** Supabase e Vercel (Carta, regra 4).
- Workflows com permissões mínimas (`contents: read`). O workflow de release isolado recebe `contents: write`, com aprovação de ambiente. Actions fixadas por SHA.

## Consequências
- ✅ Custo zero dentro dos limites gratuitos (Workers 100 mil req/dia; D1 com limites diários de leitura e escrita; ver plano do Cloud).
- ⚠️ Os limites gratuitos podem mudar: reconfirmar antes da F4.
- ⚠️ Excedido o limite diário do D1, as consultas falham: nada crítico pode depender dele.
- Pendências do usuário: criar a conta/organização no GitHub e no Cloudflare e aprovar o push.

## Fontes
- Plano de infraestrutura (Cloud): [../../infra/01-plano-infra.md](../../infra/01-plano-infra.md)
- Workers limits: <https://developers.cloudflare.com/workers/platform/limits/>
- D1 pricing / limits: <https://developers.cloudflare.com/d1/platform/pricing/> · <https://developers.cloudflare.com/d1/platform/limits/>
- GitHub Pages limits: <https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits>
- Artifact attestations: <https://docs.github.com/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds>
- Carta, regra 4: [../00-CARTA-DO-PROJETO.md](../00-CARTA-DO-PROJETO.md)
