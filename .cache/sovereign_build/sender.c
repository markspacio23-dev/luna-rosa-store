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

typedef struct __attribute__((packed)) {
    struct ethhdr eth;
    SovereignHeaderOOB header;
    uint8_t payload[MAX_PAYLOAD_SIZE];
} SovereignFullPacket;

int main(int argc, char *argv[]) {
    if (argc < 3) return 1;
    char *iface = argv[1];
    uint8_t sig_val = (uint8_t)strtol(argv[2], NULL, 16);

    int sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (sockfd < 0) return 1;

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, iface, IFNAMSIZ - 1);
    if (ioctl(sockfd, SIOCGIFINDEX, &ifr) < 0) { close(sockfd); return 1; }
    if (ioctl(sockfd, SIOCGIFHWADDR, &ifr) < 0) { close(sockfd); return 1; }

    SovereignFullPacket pkt;
    memset(&pkt, 0, sizeof(pkt));
    memset(pkt.eth.h_dest, 0xFF, 6);
    memcpy(pkt.eth.h_source, ifr.ifr_hwaddr.sa_data, 6);
    pkt.eth.h_proto = htons(0x88B5);

    pkt.header.magic = SOVEREIGN_MAGIC;
    pkt.header.src_node = 0x0001 | (1 << 15);
    pkt.header.dst_node = 0xFFFF;
    pkt.header.seq = 1001;
    pkt.header.oob_byte = sig_val ^ 0xAA;
    
    char *msg = "OOB Stream";
    pkt.header.payload_len = strlen(msg);
    memcpy(pkt.payload, msg, pkt.header.payload_len);

    struct sockaddr_ll sll;
    memset(&sll, 0, sizeof(sll));
    sll.sll_family = AF_PACKET;
    sll.sll_ifindex = ifr.ifr_ifindex;
    sll.sll_halen = ETH_ALEN;
    memset(sll.sll_addr, 0xFF, ETH_ALEN);

    size_t total = sizeof(struct ethhdr) + sizeof(SovereignHeaderOOB) + pkt.header.payload_len;
    sendto(sockfd, &pkt, total, 0, (struct sockaddr *)&sll, sizeof(sll));
    printf("[+] Trama OOB enviada con señal 0x%02X\n", sig_val);
    
    close(sockfd);
    return 0;
}
