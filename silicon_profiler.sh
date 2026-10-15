#!/usr/bin/env bash
# ==============================================================================
# SILICON PROFILER: Auditoría de Geometría de Memoria y Telemetría de Silicio
# Niveles 1 y 2: MMU, Paginación, IOMMU, Jerarquía de Caché y Latencia RDTSCP
# ==============================================================================

set -euo pipefail

# Colores de salida
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
echo "================================================================================"
echo "          SILICON & MEMORY GEOMETRY PROFILER (x86_64 HARDWARE AUDIT)            "
echo "================================================================================"
echo -e "${NC}"

# 1. VERIFICACIÓN DE ARQUITECTURA BASE Y PRIVILEGIOS
echo -e "${YELLOW}[+] 1. AUDITORÍA DE ARQUITECTURA Y MODOS DE VIRTUALIZACIÓN${NC}"
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}[!] Error: Este script requiere una arquitectura x86_64 física.${NC}"
    exit 1
fi

# Detectar banderas de virtualización y paginación
CPU_FLAGS=$(grep -m1 '^flags' /proc/cpuinfo || true)

# Paginación de 4 niveles vs 5 niveles
if echo "$CPU_FLAGS" | grep -qw "la57"; then
    echo -e "  - Esquema de Paginación:       ${GREEN}5 Niveles (57-bit Canonical Address / 128 PB Space)${NC}"
else
    echo -e "  - Esquema de Paginación:       ${GREEN}4 Niveles (48-bit Canonical Address / 256 TB Space)${NC}"
fi

# Soporte de Virtualización por Hardware
if echo "$CPU_FLAGS" | grep -qw "vmx"; then
    echo -e "  - Extensiones de Hipervisor:   ${GREEN}Intel VT-x (VMX Root/Non-Root Modes)${NC}"
elif echo "$CPU_FLAGS" | grep -qw "svm"; then
    echo -e "  - Extensiones de Hipervisor:   ${GREEN}AMD-V (SVM Host/Guest Modes)${NC}"
else
    echo -e "  - Extensiones de Hipervisor:   ${RED}No detectadas o bloqueadas por BIOS/Hipervisor${NC}"
fi

# Paginación Anidada (EPT / NPT)
if echo "$CPU_FLAGS" | grep -qw "ept"; then
    echo -e "  - Paginación Anidada (SLAT):   ${GREEN}Intel EPT (Extended Page Tables) Activo${NC}"
elif echo "$CPU_FLAGS" | grep -qw "npt"; then
    echo -e "  - Paginación Anidada (SLAT):   ${GREEN}AMD NPT (Nested Page Tables) Activo${NC}"
else
    echo -e "  - Paginación Anidada (SLAT):   ${RED}No disponible en este contexto${NC}"
fi

# Bit NX (No-Execute / Page Protection)
if echo "$CPU_FLAGS" | grep -qw "nx"; then
    echo -e "  - Protección de Bit NX (XD):  ${GREEN}Habilitado en Hardware (Bit 63 de Page Tables)${NC}"
else
    echo -e "  - Protección de Bit NX (XD):  ${RED}Deshabilitado (Vulnerable a inyección directa de código)${NC}"
fi

echo ""

# 2. VERIFICACIÓN DE IOMMU (PROTECCIÓN DMA DE BUS PCIE)
echo -e "${YELLOW}[+] 2. AUDITORÍA DE IOMMU (AISLAMIENTO DE PERIFÉRICOS PCIE)${NC}"
if [ -d "/sys/kernel/iommu_groups" ] && [ "$(ls -A /sys/kernel/iommu_groups 2>/dev/null)" ]; then
    NUM_GROUPS=$(ls -1 /sys/kernel/iommu_groups | wc -l)
    echo -e "  - Estado de la IOMMU:          ${GREEN}ACTIVA (${NUM_GROUPS} Grupos de Aislamiento IOMMU configurados)${NC}"
    echo -e "  - Protección contra DMA:       ${GREEN}Hardware de bus traduce y restringe accesos de periféricos${NC}"
else
    echo -e "  - Estado de la IOMMU:          ${RED}INACTIVA / NO DETECTADA${NC}"
    echo -e "  - Alerta de Seguridad:         ${RED}Los dispositivos PCIe pueden acceder directamente a la RAM vía DMA sin pasar por la MMU.${NC}"
fi

echo ""

# 3. GEOMETRÍA DE LA JERARQUÍA DE CACHÉ (NIVEL 2)
echo -e "${YELLOW}[+] 3. MAPEO TOPOLÓGICO DE LA JERARQUÍA DE CACHÉ${NC}"
CACHE_BASE="/sys/devices/system/cpu/cpu0/cache"
if [ -d "$CACHE_BASE" ]; then
    for idx in "$CACHE_BASE"/index*; do
        if [ -d "$idx" ]; then
            LVL=$(cat "$idx/level")
            TYPE=$(cat "$idx/type")
            SIZE=$(cat "$idx/size")
            LINE=$(cat "$idx/coherency_line_size")
            SETS=$(cat "$idx/number_of_sets")
            WAYS=$(cat "$idx/ways_of_associativity")
            
            echo -e "  - ${BOLD}Caché L${LVL} (${TYPE}):${NC}"
            echo -e "      * Capacidad Total:        ${CYAN}${SIZE}${NC}"
            echo -e "      * Tamaño de Línea:        ${CYAN}${LINE} Bytes${NC}"
            echo -e "      * Vías de Asociatividad:  ${CYAN}${WAYS}-way set associative${NC}"
            echo -e "      * Número de Sets:         ${CYAN}${SETS} Sets${NC}"
        fi
    done
else
    echo -e "  ${RED}[!] No se pudo leer la topología de caché desde sysfs.${NC}"
fi

echo ""

# 4. INTERFAZ DE TELEMETRÍA ENERGÉTICA (RAPL)
echo -e "${YELLOW}[+] 4. AUDITORÍA DE SENSORES ENERGÉTICOS (RAPL / CANAL LATERAL)${NC}"
RAPL_DIR="/sys/class/powercap/intel-rapl"
if [ -d "$RAPL_DIR" ]; then
    echo -e "  - Driver RAPL de Linux:        ${GREEN}Presente en el Kernel${NC}"
    for domain in "$RAPL_DIR"/intel-rapl:*; do
        if [ -f "$domain/name" ] && [ -f "$domain/energy_uj" ]; then
            NAME=$(cat "$domain/name")
            ENERGY=$(cat "$domain/energy_uj")
            echo -e "      * Dominio [${NAME}]: ${CYAN}${ENERGY} microjulios ($\mu J$)${NC}"
        fi
    done
else
    echo -e "  - Driver RAPL:                 ${RED}No accesible (MSRs bloqueados o virtualización sin paso directo)${NC}"
fi

echo ""

# 5. MEDIDOR FÍSICO DE CICLOS DE RELOJ (CACHE HIT vs DRAM MISS)
echo -e "${YELLOW}[+] 5. MEDICIÓN FÍSICA DE LATENCIA TEMPORAL (RDTSCP MICRO-BENCHMARK)${NC}"

if ! command -v gcc &>/dev/null; then
    echo -e "  ${RED}[!] GCC no está instalado. Instálalo con 'sudo apt install build-essential' para compilar el medidor.${NC}"
    exit 0
fi

TEMP_C_FILE=$(mktemp /tmp/cache_bench_XXXXXX.c)
TEMP_BIN_FILE=$(mktemp /tmp/cache_bench_bin_XXXXXX)

cat << 'EOF' > "$TEMP_C_FILE"
#include <stdio.h>
#include <stdint.h>
#include <x86intrin.h>

#define ITERACIONES 10000

// Forzar una variable en una línea de caché alineada a 64 bytes
static uint8_t array[64 * 1024] __attribute__((aligned(64)));

static inline uint64_t medir_acceso(volatile uint8_t *addr) {
    unsigned int aux;
    uint64_t t1, t2;
    
    // Serializar el pipeline de la CPU y medir tiempo de inicio
    t1 = __rdtscp(&aux);
    
    // Acceso físico a la memoria (Lectura)
    volatile uint8_t valor = *addr;
    (void)valor;
    
    // Serializar y medir tiempo final
    t2 = __rdtscp(&aux);
    
    return (t2 - t1);
}

int main() {
    uint64_t ciclos_hit = 0;
    uint64_t ciclos_miss = 0;
    
    // 1. Calentar y medir CACHE HIT (El dato reside en L1D)
    for (int i = 0; i < ITERACIONES; i++) {
        // Cargar en caché
        volatile uint8_t dummy = array[0];
        (void)dummy;
        _mm_mfence();
        
        // Medir lectura desde caché
        ciclos_hit += medir_acceso(&array[0]);
    }
    
    // 2. Desalojar explícitamente con CLFLUSH y medir CACHE MISS (Lectura de DRAM)
    for (int i = 0; i < ITERACIONES; i++) {
        // Desalojar la línea de la jerarquía completa de caché
        _mm_clflush(&array[0]);
        _mm_mfence();
        
        // Medir lectura forzada a DRAM física
        ciclos_miss += medir_acceso(&array[0]);
    }
    
    printf("%lu %lu\n", ciclos_hit / ITERACIONES, ciclos_miss / ITERACIONES);
    return 0;
}
EOF

# Compilar sin optimizaciones que eliminen el acceso
gcc -O0 "$TEMP_C_FILE" -o "$TEMP_BIN_FILE" -march=native

# Ejecutar y parsear resultados
RESULTADOS=$("$TEMP_BIN_FILE")
HIT_CYCLES=$(echo "$RESULTADOS" | awk '{print $1}')
MISS_CYCLES=$(echo "$RESULTADOS" | awk '{print $2}')
DELTA=$(echo "$MISS_CYCLES - $HIT_CYCLES" | bc)

echo -e "  - Latencia Promedio ${BOLD}L1 Cache Hit:${NC}   ${GREEN}${HIT_CYCLES} Ciclos de Reloj${NC}"
echo -e "  - Latencia Promedio ${BOLD}DRAM Cache Miss:${NC} ${RED}${MISS_CYCLES} Ciclos de Reloj${NC}"
echo -e "  - ${BOLD}Delta Físico ($\Delta t$ del Canal Lateral):${NC}  ${YELLOW}${DELTA} Ciclos de Reloj de Diferencia${NC}"

# Limpieza de temporales
rm -f "$TEMP_C_FILE" "$TEMP_BIN_FILE"

echo ""
echo -e "${CYAN}${BOLD}================================================================================${NC}"
echo -e "${CYAN}Conclusión de Dominio: Tienes una brecha temporal de ${DELTA} ciclos para inferir${NC}"
echo -e "${CYAN}accesos a memoria por hardware sin tocar el software ni leer los datos.${NC}"
echo -e "${CYAN}${BOLD}================================================================================${NC}"
