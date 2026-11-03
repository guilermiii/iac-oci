#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização (Userdata) do Worker Node - Kubernetes (kubeadm)
# Projeto: Blog-do-Zeca
# SO: Ubuntu Server 24.04 LTS (ARM aarch64)
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/k8s-worker-init.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando provisionamento do Worker Node..."

export DEBIAN_FRONTEND=noninteractive

# 1. Aguardar liberação de bloqueios de pacotes
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Aguardando liberação do bloqueio do apt/dpkg..."
    sleep 5
done

# 2. Desabilitar Swap
echo "Desabilitando swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 3. Configurar módulos de kernel para Kubernetes
echo "Configurando módulos do kernel..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 4. Configurar parâmetros de rede no sysctl
echo "Configurando parâmetros no sysctl..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 5. Instalar dependências básicas, utilitários de rede e Container Runtime (containerd)
echo "Instalando dependências e containerd..."
echo "127.0.0.1 $(hostname)" | tee -a /etc/hosts
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release containerd conntrack socat ebtables iptables-persistent

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd

# 6. Configurar repositório oficial do Kubernetes (pkgs.k8s.io) e instalar kubelet, kubeadm e kubectl
echo "Instalando kubelet, kubeadm e kubectl..."
K8S_VERSION="v1.31"
mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
chmod 644 /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# 7. Ajustar firewall nativo da OCI / iptables para permitir tráfego do cluster
if command -v ufw >/dev/null 2>&1; then
    ufw disable || true
fi
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
# Permitir tráfego interno da VCN e Pod Network antes das regras de bloqueio padrão da imagem OCI
iptables -I INPUT 1 -s 10.0.0.0/16 -j ACCEPT
iptables -I INPUT 1 -s 10.244.0.0/16 -j ACCEPT
iptables -I FORWARD 1 -j ACCEPT
if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
fi

# 8. Criar arquivo de instruções para join
cat <<'EOF' | tee /home/ubuntu/README-join.txt
Para conectar este nó Worker ao cluster Kubernetes:
1. Obtenha o comando gerado no Control Plane:
   cat /home/ubuntu/kubeadm-join.sh
2. Execute o comando com sudo neste Worker:
   sudo kubeadm join <IP-CONTROL-PLANE>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
EOF
chown ubuntu:ubuntu /home/ubuntu/README-join.txt

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Provisionamento do Worker Node concluído. Pronto para ingressar no cluster!"
