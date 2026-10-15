import struct
import sys

class ServidorSeguro:
    def __init__(self, max_buffer: int = 1024):
        self.max_buffer = max_buffer

    def procesar_stream(self, stream: bytes):
        print(f"[*] Recibiendo flujo de {len(stream)} bytes totales...")
        
        # Paso 1: Validar tamaño mínimo para leer la cabecera (4 bytes)
        if len(stream) < 4:
            print("[ERROR] Flujo demasiado corto: falta la cabecera de tamaño.")
            return False
            
        # Paso 2: Extraer metadatos de longitud (Paquete #0)
        tamano_declarado = struct.unpack("!I", stream[0:4])[0]
        print(f"[METADATA] Tamaño declarado en cabecera: {tamano_declarado} bytes")
        
        # Paso 3: Validación estricta de límites (Prevención de Buffer Overflow)
        if tamano_declarado > self.max_buffer:
            print(f"[ABORTO ATÓMICO] El tamaño excede el límite permitido ({self.max_buffer} bytes). Conexión purgada.")
            return False
            
        payload = stream[4:]
        if len(payload) != tamano_declarado:
            print(f"[ERROR] Incoherencia de red: Payload real ({len(payload)}) no coincide con la cabecera ({tamano_declarado}).")
            return False
            
        # Paso 4: Inicialización segura del búfer una vez verificado
        buffer_destino = bytearray(tamano_declarado)
        buffer_destino[:] = payload
        print(f"[OK] Búfer asignado y procesado de forma segura. Contenido: {buffer_destino.decode('utf-8')}")
        return True

if __name__ == "__main__":
    servidor = ServidorSeguro(max_buffer=50)
    
    print("--- PRUEBA 1: Flujo Válido ---")
    payload_valido = b"Hola, arquitectura segura!"
    stream_valido = struct.pack("!I", len(payload_valido)) + payload_valido
    servidor.procesar_stream(stream_valido)
    
    print("\n--- PRUEBA 2: Intento de Buffer Overflow ---")
    payload_malicioso = b"A" * 100
    stream_malicioso = struct.pack("!I", len(payload_malicioso)) + payload_malicioso
    servidor.procesar_stream(stream_malicioso)

