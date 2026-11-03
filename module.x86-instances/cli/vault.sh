#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização (Userdata) da Instância x86 - HashiCorp Vault
# Projeto: vault
# SO: Ubuntu Server 24.04 LTS (x86_64 Micro)
# Subnet: Privada (Zero Inbound da Internet Pública)
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/vault-init.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando provisionamento da instância Vault..."

export DEBIAN_FRONTEND=noninteractive

# 1. Aguardar liberação de bloqueios do apt/dpkg
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Aguardando liberação do bloqueio do apt/dpkg..."
    sleep 5
done

# 2. Atualizar pacotes do sistema
apt-get update -y
apt-get install -y curl gpg lsb-release jq unzip

# 3. Criar estrutura de diretórios para o Vault
mkdir -p /opt/vault/data
mkdir -p /etc/vault.d

# 4. Criar arquivo de configuração base (template)
cat <<'EOF' | tee /etc/vault.d/vault.hcl
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

ui = true
api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
EOF

chmod 640 /etc/vault.d/vault.hcl

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Provisionamento base do Vault concluído com sucesso!"
