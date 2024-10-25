# Monitoramento e Automação de Atualização do Windows Server

Este repositório contém três scripts PowerShell para automatizar o processo de monitoramento de serviços, logoff de usuários e atualização do sistema em servidores Windows, orquestrados por um playbook Ansible.

## Arquivos

- **checkServices.ps1**: Script que verifica o status de uma lista de serviços. Se todos os serviços estiverem parados, ele executa o script de atualização do Windows.
- **logoff_users.ps1**: Realiza o logoff de todos os usuários conectados ao servidor, mantendo apenas o usuário que executa o script conectado.
- **updateWindows.ps1**: Verifica atualizações do Windows e instala todas as disponíveis, ignorando uma atualização específica que pode causar problemas.

## Objetivo dos Scripts

### checkServices.ps1

- **Propósito**: Monitorar uma lista de serviços críticos em execução no servidor. Quando todos os serviços especificados são detectados como parados, ele aciona o processo de atualização do sistema.
- **Como Funciona**:
  - Verifica o status dos serviços listados usando `Get-Service`.
  - Registra o status de cada serviço em um arquivo de log.
  - Se todos os serviços estiverem parados, ele executa o script `updateWindows.ps1` para iniciar as atualizações do sistema.
  - O script é orquestrado pelo Ansible, que garante que ele seja executado no momento apropriado em cada servidor.

### logoff_users.ps1

- **Propósito**: Desconectar todos os usuários ativos no servidor, exceto o usuário que executa o script, preparando o ambiente para a manutenção.
- **Como Funciona**:
  - Identifica o usuário atual que está executando o script.
  - Lista todas as sessões de usuários no servidor.
  - Faz logoff de todas as sessões, exceto a do usuário que executa o script.
  - Cria um arquivo de flag para indicar que o processo de logoff foi concluído, permitindo que o Ansible saiba que pode prosseguir com as próximas etapas de atualização.

### updateWindows.ps1

- **Propósito**: Realizar a atualização do Windows de forma automatizada, ignorando uma atualização específica que pode causar problemas (por exemplo, uma atualização de driver de impressora que não é relevante).
- **Como Funciona**:
  - Usa o módulo `PSWindowsUpdate` para buscar atualizações disponíveis.
  - Filtra e ignora a atualização problemática, garantindo que ela não seja instalada.
  - Instala todas as outras atualizações disponíveis, registrando o progresso e quaisquer erros em um arquivo de log.
  - Cria um arquivo de flag para indicar que as atualizações foram concluídas, permitindo que o Ansible saiba que pode avançar para o próximo passo, como reiniciar o servidor.

## Observação Importante: Ajuste dos Caminhos dos Diretórios

**Os diretórios e caminhos dos scripts podem variar de máquina para máquina.** Certifique-se de ajustar os caminhos no início de cada script para refletir a estrutura de diretórios específica de cada servidor. Exemplos de caminhos como `<CAMINHO>` e `<PROJETO>` são genéricos e devem ser modificados conforme necessário.

### Exemplos de Caminhos a Serem Ajustados:

- Caminho dos scripts `logoff_users.ps1` e `updateWindows.ps1` no `checkServices.ps1`:
  
  ```powershell
  $LOGOFF_SCRIPT_PATH = "C:\\Path\\Para\\Scripts\\logoff_users.ps1"
  $UPDATE_SCRIPT_PATH = "C:\\Path\\Para\\Scripts\\updateWindows.ps1"
  ```

- Caminho do arquivo de log em cada script:
  
  ```powershell
  $LOG_FILE = "C:\\Path\\Para\\Logs\\services_status.log"
  ```

Verifique e ajuste esses caminhos antes de executar os scripts em cada servidor para garantir que eles funcionem corretamente.

## Como os Scripts Funcionam em Conjunto

1. **Monitoramento de Serviços**:
   - O `checkServices.ps1` é executado pelo Ansible para monitorar se os serviços críticos estão em execução.
   - Enquanto algum serviço estiver ativo, ele espera e verifica novamente.
   - Quando todos os serviços são detectados como parados, o script aciona o `updateWindows.ps1` para iniciar as atualizações.

2. **Logoff de Usuários**:
   - O Ansible também executa o `logoff_users.ps1` para garantir que todos os usuários, exceto o administrador atual, sejam desconectados antes de iniciar a atualização.
   - Isso ajuda a prevenir problemas durante o processo de atualização, como arquivos abertos e conexões ativas que podem interferir nas atualizações.

3. **Processo de Atualização**:
   - O `updateWindows.ps1` é chamado para buscar e instalar atualizações. Ele ignora qualquer atualização que possa causar problemas e prossegue com as demais.
   - Ao concluir, o script cria um arquivo de flag (`update_completed.flag`) que o Ansible usa para verificar que a etapa foi concluída com sucesso.
   - Depois que a atualização é concluída, o Ansible pode iniciar o processo de reinicialização do servidor, garantindo que as atualizações sejam aplicadas corretamente.

## Estrutura de Logs e Flags

- **Logs**:
  - Os eventos de execução dos scripts são registrados em arquivos de log no caminho configurado (`services_status.log`, `logoff_log.txt`, e `windows_update.log`), permitindo rastrear o progresso de cada etapa.
- **Flags**:
  - `logoff_completed.flag`: Indica que o processo de logoff foi concluído.
  - `update_completed.flag`: Indica que as atualizações foram concluídas, permitindo que o Ansible saiba que pode prosseguir para a reinicialização.

## Integração com o Ansible

O Ansible orquestra a execução desses scripts em cada servidor, garantindo que cada passo seja realizado na ordem correta:

1. **Executa o `checkServices.ps1`**: Para monitorar os serviços e iniciar a atualização quando apropriado.
2. **Executa o `logoff_users.ps1`**: Para garantir que o ambiente esteja preparado para as atualizações.
3. **Executa o `updateWindows.ps1`**: Para aplicar as atualizações necessárias ao sistema.

Esses scripts são automatizados pelo Ansible, garantindo que sejam executados de forma consistente em todos os servidores de um ambiente de produção, mantendo-os atualizados e prontos para uso.
