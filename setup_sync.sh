#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' 

echo -e "${BLUE}============ CONFIGURADOR SYNC ALL-IN-ONE (TERMUX) ============${NC}"
echo -e "${YELLOW}[1/4] Preparando conexión segura con tu Computadora...${NC}"
echo "Por favor, ingresa la dirección IP de tu computadora (ej. 192.168.1.15):"
read -r COMP_IP
echo "Ingresa el nombre de usuario de tu computadora:"
read -r COMP_USER

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t rsa -b 4000 -f "$HOME/.ssh/id_rsa" -N ""
fi

echo -e "${YELLOW}Copiando tu clave de Termux a la Computadora. Ingresa la contraseña de tu PC:${NC}"
ssh-copy-id -o StrictHostKeyChecking=no "$COMP_USER@$COMP_IP"

echo -e "\n${YELLOW}[2/4] Configurando rutas de VS Code...${NC}"
DEFAULT_DIR="$HOME/creature-simulation"
echo "Especifica la carpeta en Termux para el proyecto [Por defecto: $DEFAULT_DIR]:"
read -r PROJECT_DIR
PROJECT_DIR="${PROJECT_DIR:-$DEFAULT_DIR}"
mkdir -p "$PROJECT_DIR"

echo "Especifica la ruta ABSOLUTA en tu COMPUTADORA (ej. /home/usuario/proyectos/creature o C:/Proyectos/creature):"
read -r COMP_DIR

echo -e "\n${YELLOW}[3/4] Instalando dependencias en Termux...${NC}"
pkg update -y && pkg install rsync lsyncd openssh -y

echo -e "\n${YELLOW}[4/4] Creando demonio de sincronización instantánea...${NC}"
CONFIG_FILE="$HOME/.config_lsyncd_creature.lua"

cat << EOL > "$CONFIG_FILE"
settings {
    logfile = "$HOME/.lsyncd_creature.log",
    statusFile = "$HOME/.lsyncd_creature.status",
    nodaemon = false
}
sync {
    default.rsync,
    source = "$PROJECT_DIR",
    target = "$COMP_USER@$COMP_IP:$COMP_DIR",
    delay = 1,
    rsync = {
        binary = "rsync",
        archive = true,
        compress = true,
        _extra = { "-e", "ssh -i $HOME/.ssh/id_rsa" }
    }
}
EOL

LAUNCHER="$HOME/sync-creature.sh"
cat << EOL > "$LAUNCHER"
#!/bin/bash
pkill -f "$CONFIG_FILE" 2>/dev/null
lsyncd "$CONFIG_FILE"
echo -e "${GREEN}¡Sincronización en tiempo real ACTIVADA!${NC}"
echo -e "${BLUE}Local (Móvil):${NC} $PROJECT_DIR"
echo -e "${BLUE}Remoto (PC):${NC} $COMP_USER@$COMP_IP:$COMP_DIR"
EOL

chmod +x "$LAUNCHER"
echo -e "\n${GREEN}======================================================="
echo -e "¡TODO LISTO! Script de instalación guardado y listo."
echo -e "=======================================================${NC}"
