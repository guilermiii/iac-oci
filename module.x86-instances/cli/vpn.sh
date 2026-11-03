#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização (Userdata) da Instância x86 - VPN Management
# Projeto: VpnManagement
# SO: Ubuntu Server 24.04 LTS (x86_64 Micro)
# Subnet: Privada (Zero Inbound da Internet Pública)
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/vpn-init.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando provisionamento da instância VPN Management..."

export DEBIAN_FRONTEND=noninteractive

# 1. Aguardar liberação de bloqueios do apt/dpkg
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Aguardando liberação do bloqueio do apt/dpkg..."
    sleep 5
done

# 2. Atualizar pacotes do sistema e ferramentas de rede
apt-get update -y
apt-get install -y curl iptables-persistent net-tools wireguard-tools

# 3. Habilitar IP Forwarding para roteamento de VPN
echo "Habilitando encaminhamento de pacotes IPv4..."
cat <<EOF | tee /etc/sysctl.d/99-vpn-forwarding.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system

# 4. Criar diretório base para configurações de VPN
mkdir -p /etc/vpn-management

cat <<'EOF' | tee /etc/vpn-management/README.txt
Instância de Gerenciamento VPN (VpnManagement)
Configurada na Subnet Privada.
Para configurar perfis de acesso ou túneis seguros WireGuard/OpenVPN,
utilize este diretório ou consulte as automações futuras.
EOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Provisionamento base de VPN concluído com sucesso!"
