#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <sys/ioctl.h>

#define SOVEREIGN_MAGIC 0x5356524EUL
#define MAX_PAYLOAD_SIZE 1024

typedef struct __attribute__((packed)) {
    uint32_t magic;       
    uint16_t src_node;    
    uint16_t dst_node;    
    uint32_t seq;         
    uint16_t payload_len; 
    uint8_t  oob_byte;    
    uint16_t checksum;    
} SovereignHeaderOOB;

int main(int argc, char *argv[]) {
    if (argc < 2) return 1;
    char *iface = argv[1];
    
    int sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sockfd < 0) {
        perror("[-] Error raw socket (ejecuta como root)");
        return 1;
    }

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, iface, IFNAMSIZ - 1);
    if (ioctl(sockfd, SIOCGIFINDEX, &ifr) < 0) {
        perror("[-] Error ioctl index");
        close(sockfd);
        return 1;
    }

    struct sockaddr_ll sll;
    memset(&sll, 0, sizeof(sll));
    sll.sll_family = AF_PACKET;
    sll.sll_ifindex = ifr.ifr_ifindex;
    sll.sll_protocol = htons(ETH_P_ALL);

    if (bind(sockfd, (struct sockaddr *)&sll, sizeof(sll)) < 0) {
        perror("[-] Error bind");
        close(sockfd);
        return 1;
    }

    printf("[*] Escuchando tráfico OOB en crudo sobre [%s]...\n", iface);
    uint8_t buffer[2048];
    while (1) {
        ssize_t len = recv(sockfd, buffer, sizeof(buffer), 0);
        if (len < (ssize_t)(14 + sizeof(SovereignHeaderOOB))) continue;

        SovereignHeaderOOB *hdr = (SovereignHeaderOOB *)(buffer + 14);
        if (hdr->magic == SOVEREIGN_MAGIC) {
            if (hdr->src_node & (1 << 15)) {
                uint8_t sig = hdr->oob_byte ^ 0xAA;
                printf("[!] ¡Señal OOB detectada! Valor oculto: 0x%02X\n", sig);
            }
        }
    }
    close(sockfd);
    return 0;
}
