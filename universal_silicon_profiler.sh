# Pega el código, guarda con CTRL+O, Enter, CTRL+X

chmod +x universal_silicon_profiler.sh
./universal_silicon_profiler.sh#!/usr/bin/env bash
# ==============================================================================
# UNIVERSAL SILICON & MEMORY PROFILER (x86_64 & ARM64 / Apple / Termux / Server)
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
echo "          UNIVERSAL SILICON & MEMORY GEOMETRY PROFILER                          "
echo "================================================================================"
echo -e "${NC}"

ARCH=$(uname -m)
OS=$(uname -s)

echo -e "  - Arquitectura Física Detectada: ${GREEN}${BOLD}${ARCH}${NC}"
echo -e "  - Sistema Operativo Base:        ${CYAN}${OS}${NC}"
echo ""

# ==============================================================================
# 1. AUDITORÍA DE ARQUITECTURA Y GEOMETRÍA DE TRADUCCIÓN
# ==============================================================================
echo -e "${YELLOW}[+] 1. GEOMETRÍA DE MEMORIA Y NIVELES DE PRIVILEGIO${NC}"

if [[ "$ARCH" == "x86_64" ]]; then
    CPU_FLAGS=$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null || true)
    
    if echo "$CPU_FLAGS" | grep -qw "la57"; then
        echo -e "  - Esquema de Paginación:       ${GREEN}5 Niveles (57-bit VA / PML5)${NC}"
    else
        echo -e "  - Esquema de Paginación:       ${GREEN}4 Niveles (48-bit VA / PML4 / CR3)${NC}"
    fi

    if echo "$CPU_FLAGS" | grep -qw "vmx"; then
        echo -e "  - Virtualización Hardware:     ${GREEN}Intel VT-x (VMX Root/Non-Root)${NC}"
    elif echo "$CPU_FLAGS" | grep -qw "svm"; then
        echo -e "  - Virtualización Hardware:     ${GREEN}AMD-V (SVM Host/Guest)${NC}"
    else
        echo -e "  - Virtualización Hardware:     ${RED}No expuesta en este entorno${NC}"
    fi

elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    PAGE_SIZE=$(getconf PAGESIZE 2>/dev/null || echo "4096")
    echo -e "  - Modelo de Privilegios:       ${GREEN}ARM Exception Levels (EL0: App, EL1: Kernel, EL2: Hypervisor, EL3: Secure)${NC}"
    echo -e "  - Registros Raíz de Memoria:   ${GREEN}TTBR0_EL1 (User Space) / TTBR1_EL1 (Kernel Space)${NC}"
    echo -e "  - Granularidad de Página:      ${CYAN}${PAGE_SIZE} Bytes ($(( PAGE_SIZE / 1024 )) KB Granule)${NC}"
else
    echo -e "  - Arquitectura no estándar:    ${YELLOW}${ARCH}${NC}"
fi

echo ""

# ==============================================================================
# 2. AUDITORÍA DE CACHÉ
# ==============================================================================
echo -e "${YELLOW}[+] 2. JERARQUÍA FÍSICA DE CACHÉ${NC}"
CACHE_BASE="/sys/devices/system/cpu/cpu0/cache"

if [ -d "$CACHE_BASE" ]; then
    for idx in "$CACHE_BASE"/index*; do
        if [ -d "$idx" ]; then
            LVL=$(cat "$idx/level" 2>/dev/null || echo "?")
            TYPE=$(cat "$idx/type" 2>/dev/null || echo "Unified")
            SIZE=$(cat "$idx/size" 2>/dev/null || echo "Unknown")
            LINE=$(cat "$idx/coherency_line_size" 2>/dev/null || echo "64")
            echo -e "  - Caché L${LVL} (${TYPE}): Capacidad = ${CYAN}${SIZE}${NC} | Línea = ${CYAN}${LINE} Bytes${NC}"
        fi
    done
else
    # Fallback para macOS o entornos sin sysfs directo
    if command -v sysctl &>/dev/null; then
        L1D=$(sysctl -n hw.l1dcachesize 2>/dev/null || echo "N/A")
        L2=$(sysctl -n hw.l2cachesize 2>/dev/null || echo "N/A")
        echo -e "  - Caché L1D: ${CYAN}${L1D} Bytes${NC}"
        echo -e "  - Caché L2:  ${CYAN}${L2} Bytes${NC}"
    else
        echo -e "  ${YELLOW}[*] Topología de caché consultable vía registros de sistema.${NC}"
    fi
fi

echo ""

# ==============================================================================
# 3. MEDIDOR NATIVO DE LATENCIA FÍSICA (HIT vs MISS EN TIEMPO REAL)
# ==============================================================================
echo -e "${YELLOW}[+] 3. MEDICIÓN FÍSICA DE LATENCIA TEMPORAL (MICRO-BENCHMARK)${NC}"

if ! command -v gcc &>/dev/null && ! command -v clang &>/dev/null; then
    echo -e "  ${RED}[!] Se requiere un compilador C (gcc o clang).${NC}"
    echo -e "      En Debian/Ubuntu:  sudo apt install build-essential"
    echo -e "      En Termux/Android: pkg install clang"
    echo -e "      En Arch/Fedora:    sudo pacman -S gcc / sudo dnf install gcc"
    exit 0
fi

CC=$(command -v clang || command -v gcc)
TEMP_C=$(mktemp /tmp/bench_XXXXXX.c)
TEMP_BIN=$(mktemp /tmp/bench_bin_XXXXXX)

if [[ "$ARCH" == "x86_64" ]]; then
# CÓDIGO NATIVO x86_64 (RDTSCP + CLFLUSH)
cat << 'EOF' > "$TEMP_C"
#include <stdio.h>
#include <stdint.h>
#include <x86intrin.h>

#define ITER 5000
static uint8_t target_buffer[64 * 1024] __attribute__((aligned(64)));

static inline uint64_t timer_read(void) {
    unsigned int aux;
    return __rdtscp(&aux);
}

int main() {
    uint64_t hit_total = 0, miss_total = 0;
    
    // Test Cache Hit
    for(int i=0; i<ITER; i++) {
        volatile uint8_t dummy = target_buffer[0];
        (void)dummy;
        _mm_mfence();
        uint64_t t1 = timer_read();
        dummy = target_buffer[0];
        uint64_t t2 = timer_read();
        hit_total += (t2 - t1);
    }
    
    // Test Cache Miss
    for(int i=0; i<ITER; i++) {
        _mm_clflush(&target_buffer[0]);
        _mm_mfence();
        uint64_t t1 = timer_read();
        volatile uint8_t dummy = target_buffer[0];
        (void)dummy;
        uint64_t t2 = timer_read();
        miss_total += (t2 - t1);
    }
    
    printf("%lu %lu\n", hit_total / ITER, miss_total / ITER);
    return 0;
}
EOF

else
# CÓDIGO NATIVO ARM64 (CNTVCT_EL0 + EVICTION BUFFER)
cat << 'EOF' > "$TEMP_C"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define ITER 5000
#define EVICT_SIZE (16 * 1024 * 1024) // 16 MB para forzar desalojo de caché

static uint8_t target_buffer[64 * 1024] __attribute__((aligned(64)));
static uint8_t *evict_buffer;

static inline uint64_t timer_read(void) {
    uint64_t val;
    asm volatile("isb\n\t"
                 "mrs %0, cntvct_el0" : "=r"(val) :: "memory");
    return val;
}

int main() {
    evict_buffer = (uint8_t *)malloc(EVICT_SIZE);
    if(!evict_buffer) return 1;
    
    uint64_t hit_total = 0, miss_total = 0;
    
    // 1. Medir Cache Hit (Dato en L1)
    for(int i=0; i<ITER; i++) {
        volatile uint8_t dummy = target_buffer[0];
        (void)dummy;
        asm volatile("dsb sy\n\tisb" ::: "memory");
        
        uint64_t t1 = timer_read();
        dummy = target_buffer[0];
        uint64_t t2 = timer_read();
        hit_total += (t2 - t1);
    }
    
    // 2. Medir Cache Miss (Desalojando la caché mediante barrido de 16MB)
    for(int i=0; i<ITER; i++) {
        // Llenar la caché con datos basura para forzar el desalojo de target_buffer
        for(size_t j=0; j<EVICT_SIZE; j += 64) {
            evict_buffer[j] += 1;
        }
        asm volatile("dsb sy\n\tisb" ::: "memory");
        
        uint64_t t1 = timer_read();
        volatile uint8_t dummy = target_buffer[0];
        (void)dummy;
        uint64_t t2 = timer_read();
        miss_total += (t2 - t1);
    }
    
    printf("%lu %lu\n", hit_total / ITER, miss_total / ITER);
    free(evict_buffer);
    return 0;
}
EOF
fi

# Compilación y ejecución
$CC -O0 "$TEMP_C" -o "$TEMP_BIN" 2>/dev/null

RESULTADOS=$("$TEMP_BIN")
HIT_TICKS=$(echo "$RESULTADOS" | awk '{print $1}')
MISS_TICKS=$(echo "$RESULTADOS" | awk '{print $2}')
DELTA=$(echo "$MISS_TICKS - $HIT_TICKS" | bc 2>/dev/null || echo "$(( MISS_TICKS - HIT_TICKS ))")

echo -e "  - Latencia Promedio ${BOLD}L1 Cache Hit:${NC}   ${GREEN}${HIT_TICKS} Ticks/Ciclos${NC}"
echo -e "  - Latencia Promedio ${BOLD}DRAM Cache Miss:${NC} ${RED}${MISS_TICKS} Ticks/Ciclos${NC}"
echo -e "  - ${BOLD}Delta Físico ($\Delta t$ Medible):${NC}       ${YELLOW}${DELTA} Ticks de Brecha Temporal${NC}"

# Limpieza
rm -f "$TEMP_C" "$TEMP_BIN"

echo ""
echo -e "${CYAN}${BOLD}================================================================================${NC}"
echo -e "${CYAN}Diagnóstico de Silicio Completado. El hardware responde a las leyes físicas.${NC}"
echo -e "${CYAN}${BOLD}================================================================================${NC}"
