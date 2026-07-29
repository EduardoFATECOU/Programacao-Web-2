#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup.sh
# ---------------------------------------------------------------------------
# Script de instalação e configuração para servir os exemplos de
# Programação Web II em uma instância AWS EC2.
#
# Suporta: Debian 12/13 e Ubuntu 22.04/24.04/26.04+
#
# Uso:
#   chmod +x setup.sh
#   sudo ./setup.sh
#
# O script:
#   1. Detecta o sistema operacional
#   2. Atualiza os pacotes do sistema
#   3. Instala o Apache2
#   4. Configura o firewall (iptables) para portas 22, 80 e 443
#   5. Copia os exemplos para /var/www/html/
#   6. Ajusta permissões
#   7. Exibe o IP público para acesso
###############################################################################

# ─── Cores para output ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✘]${NC} $1"; }

# ─── Verificar se está rodando como root ────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    err "Este script precisa ser executado como root (sudo)."
    exit 1
fi

# ─── Detectar sistema operacional ──────────────────────────────────────────
. /etc/os-release 2>/dev/null || { err "Não foi possível detectar o SO."; exit 1; }

OS_ID="$ID"
OS_CODENAME="$VERSION_CODENAME"
OS_PRETTY="$PRETTY_NAME"

log "SO detectado: $OS_PRETTY"

# Mapeamento de codenames — apenas informativo, o Apache2 funciona em todos
case "$OS_ID-$OS_CODENAME" in
    ubuntu-*)    warn "Ubuntu detectado — Apache2 disponível via apt normalmente" ;;
    debian-*)    warn "Debian detectado — Apache2 disponível via apt normalmente" ;;
    *)           warn "SO não testado — tentando instalação padrão" ;;
esac

# ─── 1. Atualizar o sistema ─────────────────────────────────────────────────
log "Atualizando lista de pacotes..."
apt-get update -y

log "Atualizando pacotes instalados..."
apt-get upgrade -y

# ─── 2. Instalar Apache2 ────────────────────────────────────────────────────
log "Instalando Apache2..."
apt-get install -y apache2

# Habilitar e iniciar o serviço
service apache2 start 2>/dev/null || apachectl start

# ─── 3. Configurar firewall (iptables) ──────────────────────────────────────
log "Configurando firewall (iptables)..."
# Permite tráfego na interface de loopback
iptables -A INPUT -i lo -j ACCEPT

# Permite conexões já estabelecidas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH (porta 22)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# HTTP (porta 80)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# HTTPS (porta 443)
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Bloqueia todo o resto
iptables -A INPUT -j DROP

# Salvar regras para manter após reboot
apt-get install -y iptables-persistent
netfilter-persistent save

log "Firewall configurado (portas 22, 80, 443 liberadas)."

# ─── 4. Copiar exemplos para /var/www/html/ ────────────────────────────────
DIR_EXEMPLOS="$(cd "$(dirname "$0")" && pwd)"
DESTINO="/var/www/html"

log "Copiando exemplos para ${DESTINO}..."
cp -r "$DIR_EXEMPLOS"/* "$DESTINO/"
# Remove o próprio setup.sh do destino
rm -f "$DESTINO/setup.sh"

# ─── 5. Ajustar permissões ─────────────────────────────────────────────────
log "Ajustando permissões..."
chown -R www-data:www-data "$DESTINO"
find "$DESTINO" -type d -exec chmod 755 {} \;
find "$DESTINO" -type f -exec chmod 644 {} \;

# ─── 6. Exibir informações de acesso ────────────────────────────────────────
PUBLIC_IP="$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo 'IP_PUBLICO_INDISPONIVEL')"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo -e "║  ${GREEN}Instalação concluída com sucesso!${NC}                        ║"
echo "║                                                              ║"
echo "║  Acesse os exemplos em:                                      ║"
echo "║    http://${PUBLIC_IP}/                          ║"
echo "║                                                              ║"
echo "║  Certifique-se de que o Security Group da AWS EC2            ║"
echo "║  permita tráfego HTTP (porta 80) para o seu IP.              ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

log "Pronto! Basta acessar o IP acima no navegador."
