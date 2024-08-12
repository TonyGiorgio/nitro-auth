use log::{info, error};
use std::io::{Read, Write};
use vsock::{VsockListener, VsockStream, VsockAddr};

const VSOCK_PORT: u32 = 5000; // You can change this port as needed

fn main() -> anyhow::Result<()> {
    pretty_env_logger::init();

    info!("Starting vsocket server on port {}", VSOCK_PORT);

    let listener = VsockListener::bind(&VsockAddr::new(libc::VMADDR_CID_ANY, VSOCK_PORT))
        .expect("bind and listen failed");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                info!("New connection from {:?}", stream.peer_addr()?);
                std::thread::spawn(move || {
                    if let Err(e) = handle_connection(stream) {
                        error!("Error handling connection: {:?}", e);
                    }
                });
            }
            Err(e) => {
                error!("Error accepting connection: {:?}", e);
            }
        }
    }

    Ok(())
}

fn handle_connection(mut stream: VsockStream) -> anyhow::Result<()> {
    let mut buffer = [0; 1024];

    loop {
        match stream.read(&mut buffer) {
            Ok(0) => break, // Connection closed
            Ok(_) => {
                info!("Received message, responding with 'hello world'");
                stream.write_all(b"hello world")?;
            }
            Err(e) => {
                error!("Error reading from stream: {:?}", e);
                break;
            }
        }
    }

    Ok(())
}