# Monitoramento de Serviços e Reboot Automático

Este repositório contém dois scripts Bash para monitoramento de serviços e reinicialização automática do servidor quando todos os serviços especificados estiverem inativos.

## Arquivos

- **checkServices.sh**: Monitora uma lista de serviços especificados e executa um script de reboot quando todos os serviços estiverem inativos.
- **reboot.sh**: Reinicia o servidor e registra o processo no log.

## Pré-requisitos

- Acesso ao `sudo` para permitir a reinicialização do servidor.
- Configuração do `systemctl` para gerenciar os serviços que deseja monitorar.
- Os scripts precisam de permissão de execução:
  
  ```bash
  chmod +x checkServices.sh reboot.sh
  ```

## Configuração

1. **Configurar os Serviços a Serem Monitorados:**  
   
   Edite o arquivo `checkServices.sh` e substitua `"service1" "service2" "firebird"` pela lista de serviços que deseja monitorar:

   ```bash
   SERVICES_TO_CHECK=("service1" "service2" "firebird")
   ```

2. **Configurar o Caminho do Script de Reboot:**  
   
   Verifique se a variável `REBOOT_SCRIPT` no `checkServices.sh` aponta para o caminho correto do `reboot.sh`:

   ```bash
   REBOOT_SCRIPT="reboot.sh"
   ```

## Uso

### 1. Executar Manualmente

Para executar o script de monitoramento manualmente, use:

```bash
./checkServices.sh
```

O script verificará os serviços especificados e registrará os eventos no arquivo `service_verification.log`. Se todos os serviços estiverem inativos, o `checkServices.sh` executará o `reboot.sh`.

### 2. Integração com `crontab`

Para automatizar a execução do script usando `crontab`, siga os passos abaixo:

1. Abra o crontab para edição:

   ```bash
   crontab -e
   ```

2. Adicione a seguinte linha para executar o `checkServices.sh` a cada 5 minutos (ajuste conforme necessário):

   ```bash
   */5 * * * * /caminho/para/checkServices.sh >> /caminho/para/service_verification.log 2>&1
   ```

   - Substitua `/caminho/para/` pelo caminho completo onde os scripts estão localizados.
   - O `crontab` irá executar o `checkServices.sh` e registrará as saídas no arquivo `service_verification.log`.

### Estrutura dos Scripts

#### checkServices.sh

- Verifica se os serviços especificados estão em execução.
- Registra no log se cada serviço está ativo ou inativo.
- Entra em um loop enquanto os serviços estiverem ativos.
- Quando todos os serviços forem finalizados, executa o `reboot.sh`.

#### reboot.sh

- Registra a preparação para o reboot no log.
- Reinicia o servidor usando `sudo reboot`.
- Aguarda o processo de reinicialização antes de registrar que o servidor foi reiniciado.

## Logs

Os logs de ambos os scripts são registrados em `service_verification.log`, contendo informações sobre:

- Status dos serviços monitorados.
- A execução e resultados do script de reboot.
- Eventos importantes como início do processo de reboot e finalização dos serviços.

## Considerações

- Certifique-se de que o usuário que executa os scripts tenha permissão para reiniciar o sistema via `sudo`.
- Configure `sudo` para não solicitar senha ao executar o comando `reboot` editando o arquivo `sudoers`:

  ```bash
  sudo visudo
  ```

  Adicione a seguinte linha (substitua `seu_usuario` pelo nome do usuário):

  ```bash
  seu_usuario ALL=(ALL) NOPASSWD: /sbin/reboot
  ```

- A execução frequente do `checkServices.sh` pode ser útil em ambientes onde os serviços precisam ser monitorados de perto para automação de reinicializações.

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para enviar *pull requests* para melhorias e ajustes.

