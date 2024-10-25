# Guia Completo para Instalação, Configuração e Uso do Sistema de Atualização de Servidores Windows com Ansible

## Visão Geral

Este guia detalha como configurar um sistema automatizado para gerenciar atualizações de servidores Windows utilizando Ansible. O processo envolve:

- Instalação e configuração do Ansible no Linux/WSL.
- Configuração de conexão entre Ansible e servidores Windows.
- Uso de scripts PowerShell para verificar e instalar atualizações.
- Automação de logoff de usuários, instalação de atualizações e reinicialização dos servidores de forma ordenada.

## 1. Requisitos do Sistema

- **Sistema Operacional**: Linux, macOS, ou Windows com WSL (Windows Subsystem for Linux).
- **Python**: Ansible é baseado em Python, portanto, é necessário ter o Python 3 instalado.

---

## 2. Instalação do Ansible e Bibliotecas Necessárias

### Passo 1: Atualizar o Sistema

Atualize os pacotes do sistema para garantir que tudo funcione corretamente.

```bash
sudo apt update && sudo apt upgrade -y
```

### Passo 2: Instalar Python e Pip

Instale o Python 3 e o Pip, caso ainda não estejam instalados.

```bash
sudo apt install python3 python3-pip -y
```

### Passo 3: Instalar o Ansible

Instale o Ansible usando o Pip:

```bash
pip3 install ansible
```

### Passo 4: Verificar a Instalação do Ansible

Verifique se o Ansible foi instalado corretamente:

```bash
ansible --version
```

### Passo 5: Instalar `pywinrm`

`pywinrm` é necessário para que o Ansible se conecte a servidores Windows:

```bash
pip3 install pywinrm
```

### Passo 6: Configurar o WinRM nos Servidores Windows

Em cada servidor Windows, execute os seguintes comandos no PowerShell com permissões administrativas para configurar o WinRM:

```powershell
winrm quickconfig
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Restart-Service winrm
```

Esses comandos configuram o WinRM para permitir conexões não criptografadas e autenticação básica, necessárias para a comunicação com o Ansible.

---

## 3. Instalação do Módulo PSWindowsUpdate

### O que é o PSWindowsUpdate?

**PSWindowsUpdate** é um módulo do PowerShell que permite gerenciar as atualizações do Windows de forma automatizada. Ele é essencial para que o script `updateWindows.ps1` funcione corretamente, pois fornece os comandos necessários para verificar e instalar atualizações.

### Passo a Passo para Instalar o PSWindowsUpdate

1. **Abrir o PowerShell como Administrador**:

   No servidor Windows, abra o PowerShell com privilégios administrativos (clique com o botão direito e selecione "Executar como administrador").

2. **Instalar o Módulo PSWindowsUpdate**:

   Execute o comando abaixo para instalar o módulo:

   ```powershell
   Install-PackageProvider -Name NuGet -Force
   Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
   ```

   - O primeiro comando instala o provedor `NuGet`, necessário para baixar e instalar módulos do PowerShell.
   - O segundo comando instala o módulo **PSWindowsUpdate**.

3. **Verificar a Instalação do Módulo**:

   Para verificar se o módulo foi instalado corretamente, execute:

   ```powershell
   Get-Module -Name PSWindowsUpdate -ListAvailable
   ```

   Se tudo estiver correto, você verá informações sobre o módulo **PSWindowsUpdate** na saída.

4. **Permitir Scripts Remotos**:

   Se você estiver enfrentando problemas ao executar scripts remotamente, pode ser necessário permitir scripts:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

   Isso permite a execução de scripts locais sem assinatura e scripts baixados de forma remota que sejam assinados por um editor confiável.

---

## 4. Configuração do Inventário Ansible

Crie um arquivo `hosts` para listar os servidores que serão gerenciados:

```bash
nano hosts
```

Adicione o conteúdo abaixo:

```ini
[windows_servers]
server1 ansible_host=<IP_DO_SERVIDOR> ansible_user=<USUARIO> ansible_password='<SENHA>' ansible_connection=winrm ansible_winrm_transport=ntlm ansible_port=5985
```

- **[windows_servers]**: Nome do grupo de servidores.
- **ansible_host**: Endereço IP do servidor.
- **ansible_user**: Usuário com permissões administrativas.
- **ansible_password**: Senha do usuário.
- **ansible_connection=winrm**: Método de conexão para servidores Windows.

### Testar Conexão com os Servidores

Verifique se o Ansible consegue se conectar aos servidores:

```bash
ansible windows_servers -i hosts -m win_ping
```

Se tudo estiver configurado corretamente, você verá uma resposta "pong" de cada servidor.

---

## 5. Configuração dos Scripts PowerShell

Todos os scripts PowerShell devem ser colocados no diretório de sua preferência, com suas devidas modificações nos scripts PowerShell e Ansible, por exemplo: `C:\Path\Para\Scripts\` em cada servidor.

## 6. Execução do Playbook Ansible

Crie o arquivo `run_check_and_reboot.yml` para automatizar o processo:

```bash
nano run_check_and_reboot.yml
```

Adicione o conteúdo abaixo:

```yaml
---
- name: Logoff de usuários, verificar serviços e reiniciar servidores
  hosts: windows_servers
  become: yes
  become_method: runas
  become_user: <USUARIO>
  tasks:
    - name: Executar script de logoff de usuários no servidor
      ansible.builtin.win_shell: |
        powershell.exe -ExecutionPolicy Bypass -File C:\Path\Para\Scripts\logoff_users.ps1
      register: logoff_result
      ignore_errors: no

    - name: Verificar se o logoff foi concluído
      ansible.builtin.win_stat:
        path: C:\Path\Para\Scripts\logoff_completed.flag
      register: logoff_flag_status
      until: logoff_flag_status.stat.exists
      retries: -1
      delay: 60

    - name: Executar script de verificação de serviços no servidor
      ansible.builtin.win_shell: |
        powershell.exe -ExecutionPolicy Bypass -File C:\Path\Para\Scripts\checkServices.ps1
      ignore_errors: no

    - name: Executar script de atualização do Windows
      ansible.builtin.win_shell: |
        powershell.exe -ExecutionPolicy Bypass -File C:\Path\Para\Scripts\updateWindows.ps1
      register: update_result
      ignore_errors: no

    - name: Verificar se a atualização foi concluída
      ansible.builtin.win_stat:
        path: C:\Path\Para\Scripts\update_completed.flag
      register: update_flag_status
      until: update_flag_status.stat.exists
      retries: -1
      delay: 60

    - name: Reiniciar o servidor após a conclusão do script de atualização
      ansible.builtin.win_reboot:
      serial: 1

    - name: Registrar log de reinicialização
      local_action: shell echo "{{ inventory_hostname }} foi reiniciado com sucesso em $(date)" >> /home/<USUARIO>/ansible_logs/reboot_log.txt
      run_once: true
```

### Executar o Playbook

Execute o playbook:

```bash
ansible-playbook -i hosts run_check_and_reboot.yml
```

---

## 7. Conclusão

Este guia completo orienta desde a instalação do Ansible e configuração dos servidores Windows até a execução do playbook de automação. Ele permite que qualquer pessoa configure e use o sistema de forma eficaz, mesmo sem conhecimento prévio do desenvolvimento dos scripts. Se precisar de mais ajuda, consulte as seções de solução de problemas e perguntas frequentes!

