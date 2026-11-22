# Criar um client_id próprio do rclone para Google Drive

O rclone está configurado para backup semanal aos domingos às 20h em `infra/backup-drive.ps1`. O client_id compartilhado do Google Drive será desativado; criar um client_id próprio, gratuito, e atualizar a configuração OAuth existente. Não compartilhe client_secret nem token.

## Google Cloud Console

1. Acesse https://console.cloud.google.com/ com a conta Google que controla o Drive e crie um projeto dedicado, por exemplo `BigZ OS rclone`.
2. Em APIs e serviços > Biblioteca, habilite **Google Drive API** para esse projeto.
3. Em APIs e serviços > Tela de consentimento OAuth, escolha **Externo** (ou Interno somente se conta Workspace e uso restrito à organização). Preencha nome do app e e-mail de suporte/contato; mantenha os escopos mínimos necessários para a pasta dedicada.
4. Configure a audiência como **Testing** e adicione a conta que fará o backup como usuário de teste, se aplicável. Para uso pessoal, não solicitar verificação pública se os escopos e o fluxo permitirem. O Google pode exibir aviso de app não verificado; não ignore avisos sem revisar o escopo apresentado.
5. Em Clientes > Criar cliente OAuth, selecione **Aplicativo para computador (Desktop app)**. Crie e baixe o JSON de credenciais; guarde-o fora do repositório e não o envie por chat.
6. No assistente local do rclone, abra `rclone config`, edite o remote Google Drive existente, informe o `client_id` e `client_secret` do novo cliente. Deixe o remote e a pasta de destino existentes intactos. Complete a autorização OAuth no navegador da conta correta e confirme o acesso solicitado.
7. Faça uma listagem de leitura da pasta de backup e um teste controlado de cópia; depois execute `infra/backup-drive.ps1` e confira o resultado. Não cole tokens nem secrets em logs ou Git.
8. Revogue o client antigo nas credenciais Google após validar o novo. Mantenha arquivo/credenciais locais protegidos e excluídos do backup/Git. Para migrar conta ou escopo, peça nova autorização ao usuário.

## Aprovações do usuário

Autorizar acesso ao Google Cloud Console, criação do projeto e cliente OAuth, consentimento da conta Google no rclone, e uma execução de teste de backup/restauração. Todas essas etapas usam serviços gratuitos no uso previsto, mas quotas e políticas podem mudar; conferir o console oficial. Nenhuma credencial foi criada ou alterada por este guia.
