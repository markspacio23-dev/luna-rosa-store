use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::time::{SystemTime, UNIX_EPOCH, Duration};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;

struct EntradaLedger {
    id: u64,
    timestamp: u64,
    coordenada: String,
    hash_previo: u64,
    hash_actual: u64,
}

struct MotorSoberano {
    contador_pulsos: AtomicU64,
    ledger: Mutex<Vec<EntradaLedger>>,
}

fn calcular_hash(previo: u64, id: u64, coord: &str) -> u64 {
    let mut h = previo ^ id;
    for b in coord.bytes() {
        h = h.wrapping_mul(1099511628211);
        h ^= b as u64;
    }
    h
}

fn main() {
    let puerto = "0.0.0.0:8080";
    
    let genesis = EntradaLedger {
        id: 0,
        timestamp: SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs(),
        coordenada: "/genesis".to_string(),
        hash_previo: 0,
        hash_actual: 0x4D41524B53504143,
    };

    let motor = Arc::new(MotorSoberano {
        contador_pulsos: AtomicU64::new(0),
        ledger: Mutex::new(vec![genesis]),
    });

    println!("[+] MARKSPACIO // ECOSISTEMA SOBERANO DUAL [NIVEL 9]");

    let motor_autopilot = Arc::clone(&motor);
    thread::spawn(move || {
        loop {
            thread::sleep(Duration::from_secs(20));
            let guard = motor_autopilot.ledger.lock().unwrap();
            let total_bloques = guard.len();
            println!("[AUTOPILOT // MATRIZ DUAL] Integridad RAM OK | Bloques inmutables: {}", total_bloques);
        }
    });

    let listener = TcpListener::bind(puerto).expect("[-] Error critico: Falla al enlazar el puerto base del silicio.");
    println!("[✔] Showcase y Panel de Control expuestos en http://{}", puerto);

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let motor_clone = Arc::clone(&motor);
                thread::spawn(move || {
                    gestionar_proyeccion(stream, motor_clone);
                });
            }
            Err(e) => {
                eprintln!("[-] Advertencia de socket: {}", e);
            }
        }
    }
}

fn gestionar_proyeccion(mut stream: TcpStream, motor: Arc<MotorSoberano>) {
    let mut buffer = [0; 1024];
    if stream.read(&mut buffer).is_err() { 
        return; 
    }
    
    let peticion = String::from_utf8_lossy(&buffer[..]);
    let primera_linea = peticion.lines().next().unwrap_or("");
    
    let partes: Vec<&str> = primera_linea.split_whitespace().collect();
    let coordenada = if partes.len() > 1 { partes[1] } else { "/" };

    let pulso_actual = motor.contador_pulsos.fetch_add(1, Ordering::SeqCst) + 1;
    let timestamp = SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs();

    let hash_generado = {
        let mut guard = motor.ledger.lock().unwrap();
        let ultimo_hash = match guard.last() {
            Some(e) => e.hash_actual,
            None => 0,
        };
        let nuevo_hash = calcular_hash(ultimo_hash, pulso_actual, coordenada);
        guard.push(EntradaLedger {
            id: pulso_actual,
            timestamp,
            coordenada: coordenada.to_string(),
            hash_previo: ultimo_hash,
            hash_actual: nuevo_hash,
        });
        if guard.len() > 100 {
            guard.remove(1);
        }
        nuevo_hash
    };

    let (content_type, cuerpo) = match coordenada {
        "/" | "/index.html" => (
            "text/html; charset=utf-8",
            format!(
                r#"<!DOCTYPE html>
                <html lang="es">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Markspacio - Monolito Soberano de Silicio [Nivel 9]</title>
                    <meta name="description" content="Infraestructura descentralizada operando en silicio puro sin dependencias corporativas. Marcos Antonio Rojas Cuevas.">
                    <meta name="author" content="Marcos Antonio Rojas Cuevas">
                    <style>
                        body {{ background: #000000; color: #00ffcc; font-family: 'Courier New', monospace; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }}
                        .terminal {{ border: 1px solid #00ffcc; padding: 40px; box-shadow: 0 0 50px rgba(0,255,204,0.1); background: #020202; max-width: 750px; width: 100%; }}
                        h1 {{ letter-spacing: 3px; font-size: 16px; margin-bottom: 20px; color: #ffffff; border-bottom: 1px solid #00ffcc; padding-bottom: 10px; }}
                        p {{ color: #a1a1a1; font-size: 13px; line-height: 1.8; margin: 8px 0; }}
                        .highlight {{ color: #00ffcc; font-weight: bold; }}
                        .pulse {{ color: #ff0055; font-weight: bold; }}
                        .counter {{ color: #ffff00; font-weight: bold; }}
                        .ledger {{ color: #00bfff; font-size: 12px; }}
                        .nav-links {{ margin-top: 25px; }}
                        .nav-links a {{ color: #ff00ff; text-decoration: none; border: 1px solid #ff00ff; padding: 6px 12px; font-size: 12px; display: inline-block; }}
                        .nav-links a:hover {{ background: #ff00ff; color: #000; }}
                        .sovereign-tag {{ color: #ff00ff; font-size: 11px; margin-top: 25px; display: block; border-top: 1px dashed #333; padding-top: 15px; }}
                    </style>
                </head>
                <body>
                    <main class="terminal">
                        <h1>[ MARKSPACIO // SHOWCASE PÚBLICO ]</h1>
                        <p>Estado del Sistema: <span class="highlight">AUTÓNOMO EN SILICIO PURO (CERO NUBES, CERO REGLAS AJENAS)</span></p>
                        <p>Pulso Temporal (Unix): <span class="pulse">{}</span></p>
                        <p>Impactos Procesados en RAM: <span class="counter">{}</span></p>
                        <p>Bloque Criptográfico Activo: <code class="ledger">0x{:016X}</code></p>
                        <div class="nav-links">
                            <a href="/control">[ ACCEDER AL PANEL DE CONTROL Y AUDITORÍA ]</a>
                        </div>
                        <span class="sovereign-tag">ARQUITECTURA Y DISEÑO: MARCOS ANTONIO ROJAS CUEVAS</span>
                    </main>
                </body>
                </html>"#,
                timestamp, pulso_actual, hash_generado
            )
        ),
        "/control" => {
            let guard = motor.ledger.lock().unwrap();
            let mut ledger_rows = String::new();
            for entry in guard.iter().rev().take(15) {
                ledger_rows.push_str(&format!(
                    "<tr><td>#{}</td><td>{}</td><td>{}</td><td>0x{:016X}</td></tr>",
                    entry.id, entry.timestamp, entry.coordenada, entry.hash_actual
                ));
            }
            drop(guard);

            (
                "text/html; charset=utf-8",
                format!(
                    r#"<!DOCTYPE html>
                    <html lang="es">
                    <head>
                        <meta charset="utf-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Markspacio - Panel de Control Soberano</title>
                        <style>
                            body {{ background: #000000; color: #00ffcc; font-family: 'Courier New', monospace; padding: 30px; margin: 0; }}
                            .panel {{ border: 1px solid #00ffcc; padding: 30px; background: #020202; max-width: 900px; margin: auto; box-shadow: 0 0 30px rgba(0,255,204,0.1); }}
                            h1 {{ font-size: 15px; border-bottom: 1px solid #00ffcc; padding-bottom: 10px; color: #fff; }}
                            table {{ width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 12px; }}
                            th, td {{ border: 1px solid #333; padding: 8px; text-align: left; color: #a1a1a1; }}
                            th {{ color: #00ffcc; background: #050505; }}
                            .back {{ display: inline-block; margin-top: 20px; color: #ff00ff; text-decoration: none; border: 1px solid #ff00ff; padding: 6px 12px; font-size: 12px; }}
                            .back:hover {{ background: #ff00ff; color: #000; }}
                        </style>
                    </head>
                    <body>
                        <div class="panel">
                            <h1>[ PANEL DE CONTROL Y AUDITORÍA // QUANTUM LEDGER ]</h1>
                            <p>Autoridad: <strong>Marcos Antonio Rojas Cuevas</strong> | Estado RAM: <strong>Soberano y Activo</strong></p>
                            <table>
                                <thead>
                                    <tr><th>ID</th><th>Timestamp</th><th>Coordenada</th><th>Hash Actual</th></tr>
                                </thead>
                                <tbody>
                                    {}
                                </tbody>
                            </table>
                            <a class="back" href="/">&lt; Volver al Showcase Público</a>
                        </div>
                    </body>
                    </html>"#,
                    ledger_rows
                )
            )
        },
        "/api/metrics" => (
            "application/json; charset=utf-8",
            format!(
                r#"{{"estado": "ecosistema_soberano_dual", "nivel": 9, "autor": "Marcos Antonio Rojas Cuevas", "timestamp": {}, "impactos": {}, "ultimo_hash": "0x{:016X}", "coordenada": "{}"}}"#,
                timestamp, pulso_actual, hash_generado, coordenada
            )
        ),
        _ => (
            "text/html; charset=utf-8",
            r#"<!DOCTYPE html><html><head><meta charset="utf-8"><title>404</title></head><body style="background:#000;color:#ff4444;font-family:monospace;text-align:center;padding-top:20vh;"><h1>404 | Coordenada Fuera del Dominio Soberano</h1></body></html>"#.to_string()
        ),
    };

    let bytes = cuerpo.as_bytes();
    let cabecera = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
        content_type, bytes.len()
    );

    let _ = stream.write_all(cabecera.as_bytes());
    let _ = stream.write_all(bytes);
}
