use crate::storage::Storage;
use std::io::{self, Read};

pub struct Editor {
    filename: String,
}

impl Editor {
    pub fn new(filename: String) -> Self {
        Self { filename }
    }

    pub fn run(&self) {
        print!("\x1B[2J\x1B[1;1H");
        println!("=== MBARETE CODE [Global Engine V4.0] ===");
        println!("Soberanía Tecnológica desde Paraguay para el Mundo");
        println!("--------------------------------------------------");
        println!("Archivo activo: {}", self.filename);
        
        match Storage::read_file(&self.filename) {
            Ok(contents) => {
                println!("--- [Contenido en Disco] ---");
                print!("{}", contents);
            }
            Err(_) => {
                println!("[Aviso: Archivo nuevo. Se inicializará al guardar.]");
            }
        }
        
        println!("--------------------------------------------------");
        println!("Escribe el contenido y presiona Ctrl+D para guardar globalmente:");
        
        let mut input_buffer = String::new();
        if io::stdin().read_to_string(&mut input_buffer).is_ok() {
            match Storage::write_file(&self.filename, &input_buffer) {
                Ok(_) => println!("\n[GLOBAL_SUCCESS: Archivo guardado y sincronizado en {}]", self.filename),
                Err(e) => println!("\n[GLOBAL_ERROR: No se pudo guardar: {}]", e),
            }
        }
    }
}
