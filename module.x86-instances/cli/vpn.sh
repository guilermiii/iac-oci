#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização (Userdata) da Instância x86 - VPN WireGuard & DuckDNS
# Projeto: VpnManagement
# SO: Ubuntu Server 24.04 LTS (x86_64 Micro)
# Subnet: Pública (IP Público Efêmero, IGW direto)
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/vpn-init.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando provisionamento da instância VPN WireGuard & DuckDNS..."

export DEBIAN_FRONTEND=noninteractive

# 1. Aguardar liberação de bloqueios do apt/dpkg
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Aguardando liberação do bloqueio do apt/dpkg..."
    sleep 5
done

# 2. Atualizar pacotes do sistema e instalar dependências essenciais
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Instalando pacotes necessários (wireguard, cron, curl, etc)..."
apt-get update -y
apt-get install -y curl cron wireguard wireguard-tools iptables-persistent net-tools qrencode vim git

# Garantir que o serviço cron está ativo e habilitado no boot
systemctl enable --now cron

# 3. Configuração do DuckDNS via Crontab (atualização a cada 5 minutos)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configurando script e cron do DuckDNS..."
mkdir -p /opt/duckdns
mkdir -p /home/ubuntu/duckdns

cat << 'EOF' > /opt/duckdns/duck.sh
#!/usr/bin/env bash
echo url="https://www.duckdns.org/update?domains=__DUCKDNS_DOMAIN__&token=__DUCKDNS_TOKEN__&ip=" | curl -k -s -o /var/log/duck.log -K -
EOF

chmod 755 /opt/duckdns/duck.sh

# Criar atalhos na home do usuário ubuntu para fácil inspeção
ln -sf /opt/duckdns/duck.sh /home/ubuntu/duckdns/duck.sh
ln -sf /var/log/duck.log /home/ubuntu/duckdns/duck.log
chown -R ubuntu:ubuntu /home/ubuntu/duckdns

# Configurar cronjob do sistema para executar a cada 5 minutos
cat << 'EOF' > /etc/cron.d/duckdns
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /opt/duckdns/duck.sh >/dev/null 2>&1
EOF

chmod 644 /etc/cron.d/duckdns

# Executar imediatamente o primeiro update de DDNS e registrar no log
/opt/duckdns/duck.sh
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Status inicial do DuckDNS: $(cat /var/log/duck.log || true)"

# 4. Habilitar IP Forwarding no Kernel
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Habilitando net.ipv4.ip_forward..."
cat << 'EOF' > /etc/sysctl.d/99-vpn-forwarding.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system

# 5. Geração de Chaves Criptográficas e Configuração do Servidor WireGuard
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configurando servidor WireGuard e clientes..."
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
mkdir -p /home/ubuntu/wireguard-clients
chmod 700 /home/ubuntu/wireguard-clients

# Gerar chaves do Servidor
SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)

# Gerar chaves do Cliente 1: Notebook
NOTEBOOK_PRIV_KEY=$(wg genkey)
NOTEBOOK_PUB_KEY=$(echo "${NOTEBOOK_PRIV_KEY}" | wg pubkey)

# Gerar chaves do Cliente 2: Servidor On-Premise
ONPREMISE_PRIV_KEY=$(wg genkey)
ONPREMISE_PUB_KEY=$(echo "${ONPREMISE_PRIV_KEY}" | wg pubkey)

# Gerar chaves do Cliente 3: GitHub Actions Runner (Futuro)
RUNNER_PRIV_KEY=$(wg genkey)
RUNNER_PUB_KEY=$(echo "${RUNNER_PRIV_KEY}" | wg pubkey)

# 6. Criar /etc/wireguard/wg0.conf no Servidor
# O roteamento iptables é estritamente restrito entre os peers na interface wg0 (-i wg0 -o wg0),
# impedindo que o tráfego da VPN acesse as subnets da OCI.
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.200.0.1/24
ListenPort = 51820
PrivateKey = ${SERVER_PRIV_KEY}
SaveConfig = false

# Roteamento restrito exclusivamente entre os peers da VPN (wg0 <-> wg0)
PostUp = iptables -A FORWARD -i wg0 -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o wg0 -j ACCEPT

# Peer 1: Notebook
[Peer]
PublicKey = ${NOTEBOOK_PUB_KEY}
AllowedIPs = 10.200.0.2/32

# Peer 2: Servidor On-Premise
[Peer]
PublicKey = ${ONPREMISE_PUB_KEY}
AllowedIPs = 10.200.0.3/32

# Peer 3: GitHub Runner (Futuro)
[Peer]
PublicKey = ${RUNNER_PUB_KEY}
AllowedIPs = 10.200.0.4/32
EOF

chmod 600 /etc/wireguard/wg0.conf

# 7. Criar arquivos de configuração prontos para os Clientes em /home/ubuntu/wireguard-clients/

# 7.1. Perfil do Notebook (AllowedIPs restrito estritamente ao Servidor On-Premise 10.200.0.3/32)
cat << EOF > /home/ubuntu/wireguard-clients/notebook.conf
[Interface]
PrivateKey = ${NOTEBOOK_PRIV_KEY}
Address = 10.200.0.2/24

[Peer]
PublicKey = ${SERVER_PUB_KEY}
Endpoint = __DUCKDNS_DOMAIN__.duckdns.org:51820
AllowedIPs = 10.200.0.3/32
PersistentKeepalive = 25
EOF

# 7.2. Perfil do Servidor On-Premise (com keepalive persistente para atravessar o NAT residencial)
cat << EOF > /home/ubuntu/wireguard-clients/onpremise.conf
[Interface]
PrivateKey = ${ONPREMISE_PRIV_KEY}
Address = 10.200.0.3/24

[Peer]
PublicKey = ${SERVER_PUB_KEY}
Endpoint = __DUCKDNS_DOMAIN__.duckdns.org:51820
AllowedIPs = 10.200.0.2/32, 10.200.0.4/32
PersistentKeepalive = 25
EOF

# 7.3. Perfil do GitHub Runner (Futuro)
cat << EOF > /home/ubuntu/wireguard-clients/github-runner.conf
[Interface]
PrivateKey = ${RUNNER_PRIV_KEY}
Address = 10.200.0.4/24

[Peer]
PublicKey = ${SERVER_PUB_KEY}
Endpoint = __DUCKDNS_DOMAIN__.duckdns.org:51820
AllowedIPs = 10.200.0.3/32
PersistentKeepalive = 25
EOF

# Gerar QR Code em texto do perfil do notebook
qrencode -t ansiutf8 < /home/ubuntu/wireguard-clients/notebook.conf > /home/ubuntu/wireguard-clients/notebook.qr.txt || true

# Permissões adequadas para o usuário ubuntu acessar via Bastion
chown -R ubuntu:ubuntu /home/ubuntu/wireguard-clients
chmod 600 /home/ubuntu/wireguard-clients/*.conf || true
chmod 644 /home/ubuntu/wireguard-clients/*.qr.txt || true

# 8. Habilitar e iniciar serviço WireGuard
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando serviço wg-quick@wg0..."
systemctl enable --now wg-quick@wg0

# Criar arquivo de boas-vindas com instruções
cat << 'EOF' > /home/ubuntu/README-VPN.txt
==============================================================================
Instância VPN WireGuard & DuckDNS (VpnManagement)
==============================================================================

DuckDNS:
  - Script: /opt/duckdns/duck.sh (ou ~/duckdns/duck.sh)
  - Log: cat ~/duckdns/duck.log (ou /var/log/duck.log)
  - Cron: /etc/cron.d/duckdns (executa a cada 5 minutos)

WireGuard:
  - Status do servidor: sudo wg show
  - Configurações dos clientes disponíveis em: ~/wireguard-clients/
      * notebook.conf       -> Configuração para o seu Notebook (acessa 10.200.0.3)
      * onpremise.conf      -> Configuração para o Servidor On-Premise
      * github-runner.conf  -> Configuração para o Runner do GitHub

Conectividade:
  - Conectado à VPN pelo seu Notebook, você acessará diretamente o
    Servidor On-Premise no IP: 10.200.0.3
==============================================================================
EOF
chown ubuntu:ubuntu /home/ubuntu/README-VPN.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Provisionamento da VPN WireGuard e DuckDNS concluído com sucesso!"
