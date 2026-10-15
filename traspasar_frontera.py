import socket
import sys

def cruzar_frontera(host, puerto):
    print(f"[*] Apuntando al objetivo en la frontera: {host}:{puerto}")
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(4.0)
    try:
        s.connect((host, puerto))
        print(f"[+] ¡FRONTERA ATRAVESADA! Conexión establecida con éxito hacia {host}:{puerto}")
        sondeo = b"GET / HTTP/1.1\r\nHost: " + host.encode() + b"\r\nConnection: close\r\n\r\n"
        print(f"[*] Enviando sondeo de bajo nivel ({len(sondeo)} bytes)...")
        s.sendall(sondeo)
        respuesta_cruda = s.recv(4096)
        if respuesta_cruda:
            print(f"\n[<<] RESPUESTA CAPTURADA DE LA FRONTERA ({len(respuesta_cruda)} bytes):")
            print("-" * 40)
            print(respuesta_cruda.decode('utf-8', errors='ignore'))
            print("-" * 40)
        else:
            print("[!] El nodo cerró la conexión sin emitir datos en el banner.")
    except socket.timeout:
        print("[!] Tiempo de espera agotado: La frontera está blindada o filtra el tráfico.")
    except ConnectionRefusedError:
        print("[!] Conexión rechazada: El servicio está inactivo o detrás de un firewall estricto.")
    except Exception as e:
        print(f"[!] Excepción en el cruce de frontera: {e}")
    finally:
        s.close()
        print("[*] Socket cerrado de forma segura.")

if __name__ == "__main__":
    objetivo_host = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1"
    objetivo_puerto = int(sys.argv[2]) if len(sys.argv) > 2 else 9999
    cruzar_frontera(objetivo_host, objetivo_puerto)
