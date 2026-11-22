# ADR-010 — Licença das VMs de teste

- **Status:** Aceita (proposta da Beatrix, a ratificar pelo Auron) · **Data:** 2026-11-21 · **Dona:** Beatrix · **Revisores:** Cid, Auron

## Contexto
O laboratório de QA (F2) precisa de Windows 11 em VMs Hyper-V. A licença do Windows conta **cada VM como uma instância** que precisa de licença (§2.d.iv). Ela também diz que o uso só é autorizado se o software estiver "properly licensed" e "properly activated" (§5). Há duas opções práticas:

| Opção | Como é | Avaliação |
|---|---|---|
| **A. ISO de consumidor (Home/Pro) instalada sem chave** | O instalador permite seguir "sem chave de produto"; o Windows fica sem ativação | ❌ Tecnicamente possível, mas o uso sem licença e sem ativação **não é autorizado** pela §5. Não serve como padrão de um projeto que se vende como "confiável". Também não testa a ativação |
| **B. Windows 11 Enterprise Evaluation (90 dias)** | Mídia oficial do Microsoft Evaluation Center, feita para avaliação e teste | ✅ Licenciada para avaliação, gratuita e renovável reinstalando. ⚠️ É **Enterprise**, não Home/Pro: os apps pré-instalados, as políticas e os recursos diferem |

## Decisão
1. **Padrão do laboratório: Enterprise Evaluation (opção B).** Um ciclo de 90 dias por VM. Ao vencer, **reinstalar**. Nunca estender o prazo (`slmgr /rearm` ou equivalentes) nem usar ativadores (ADR-007).
2. **A opção A está proibida** como prática do projeto (VM de consumidor sem chave).
   - A **ISO de consumidor** (Ferramenta de Criação de Mídia, multi-edição) **pode e deve** ser usada como **entrada do builder** (`-Plan`, inventário, build). É a mídia que os usuários terão. **Instalar** a ISO gerada numa VM exige licença Home/Pro real para aquela VM (item 3). Sem ela, a instalação de teste usa a Enterprise Evaluation com `-TestOnly`.
   - A licença Pro do PC host **não cobre** a VM: é uma licença por instância (§2.d.iv).
3. **Validação de Home/Pro** (obrigatória antes de anunciar suporte, v1): só com **licença real**:
   - uma licença Home/Pro própria dedicada àquela VM (uma licença por instância); ou
   - uma máquina física de testes com a licença OEM dela (essa também é a única forma de testar GPU, drivers e anti-cheat).
   - Outras formas de licença (ex.: assinatura Visual Studio com direitos de dev/teste) só depois de confirmar os termos (não verificado).
4. **Restrições do modo `-TestOnly` do builder (Cid):**
   - Aceita **apenas** a imagem cujo `EditionId` original seja `EnterpriseEval`. Recusa qualquer outra edição em `-TestOnly`. Sem `-TestOnly`, recusa `EnterpriseEval`, porque a matriz de suporte é Home/Pro.
   - A saída é marcada como teste em todos os lugares: `testOnly: true` no manifesto, sufixo `-TESTONLY` no nome do arquivo e aviso nos logs. O CI e o workflow de release **recusam** qualquer artefato com `testOnly` (e ISOs em geral, ADR-001).
   - **Licença e ativação intocadas:** sem `ProductKey` no `autounattend.xml`, sem mudar o canal de licença e sem burlar requisitos (sem `LabConfig`/`BypassTPMCheck` etc.). Também sem aceitar a licença em nome de quem testa: no `-TestOnly`, não preencher `AcceptEula`; a tela de termos fica para o testador aceitar.
   - Mídia **local**: fica em `C:\DEV\BigZ-Lab\iso\`, fora do repositório, das releases e do backup do Drive. Nenhum agente baixa a ISO: o cadastro no Evaluation Center é do usuário. O SHA-256 da ISO é registrado no manifesto e nas Notes da VM.
   - Os relatórios de QA dizem a edição testada ("Enterprise Evaluation, build X"). Um resultado em Enterprise **não** vale como prova de compatibilidade com Home/Pro.
5. Contas na VM: só **contas locais de laboratório** ou uma conta Microsoft de teste dedicada. Nunca as contas pessoais do usuário.

## Consequências
- ✅ Laboratório 100% licenciado e gratuito, coerente com a Carta (regra 1) e com o ADR-007.
- ⚠️ Retrabalho a cada 90 dias: reinstalar a VM e refazer o checkpoint "limpo". Os scripts de `tests/hyperv/` reduzem isso a poucos comandos.
- ⚠️ Existe uma lacuna Enterprise × Home/Pro, que exige pelo menos uma licença Home/Pro real ou uma máquina física antes do v1. **Custo a aprovar pelo usuário.**
- **[ADVOGADO]** Os termos de licença específicos da avaliação (exibidos na instalação) não foram lidos nesta pesquisa (não verificado). O testador deve ler e guardar uma cópia na primeira instalação.

## Fontes
- Licença do Windows 11 (OEM, abr/2024), §2.d.iv (uma licença por instância, física ou virtual) e §5 (uso autorizado só com licença e ativação): <https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/11/oem-(pre-installed)/UseTerms_OEM_Windows_11_English.pdf>
- Microsoft Evaluation Center, Windows 11 Enterprise (90 dias): <https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise>
- Relatório de segurança/QA, seções 1.1 e 4.1: [../02-seguranca-legal-qa.md](../02-seguranca-legal-qa.md)
- Roteiro da VM: [../qa/roteiro-vm-hyperv-referencia.md](../qa/roteiro-vm-hyperv-referencia.md)
- ADR-001 (sem distribuir ISO) e ADR-007 (sem ativadores)
