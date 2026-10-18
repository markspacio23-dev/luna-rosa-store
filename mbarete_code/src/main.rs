mod storage;
mod editor;

use std::env;
use editor::Editor;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() > 1 {
        let filename = args[1].clone();
        let editor = Editor::new(filename);
        editor.run();
    } else {
        print!("\x1B[2J\x1B[1;1H");
        println!("=== MBARETE CODE [Global Engine V4.0] ===");
        println!("Uso global: cargo run -- <archivo>");
    }
}
