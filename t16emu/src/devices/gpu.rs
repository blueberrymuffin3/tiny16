use std::thread::JoinHandle;

use crate::memory::Memory;
use bytemuck::{Pod, Zeroable};
use oneshot::Sender;
use softbuffer::GraphicsContext;
use winit::event::{Event, WindowEvent};
use winit::event_loop::{ControlFlow, EventLoopProxy, EventLoopBuilder};
use winit::window::WindowBuilder;

const TILEMAP_WIDTH: usize = 64;
const TILEMAP_HEIGHT: usize = 64;
const TILEMAP_SIZE: usize = TILEMAP_WIDTH * TILEMAP_HEIGHT / 2;

const TILE_SIZE: usize = 8;
const TILESET_COUNT: usize = 256;
const TILESET_SIZE: usize = TILE_SIZE * TILE_SIZE * TILESET_COUNT;

#[derive(Copy, Clone, Pod, Zeroable)]
#[repr(C, packed)]
struct VRAM {
    tilemap: [u16; TILEMAP_SIZE],
    tileset: [u16; TILEMAP_SIZE],
}

struct GPUState {
    handle: Option<JoinHandle<()>>,
    proxy: EventLoopProxy<ProxyMessage>,
}

impl Drop for GPUState {
    fn drop(&mut self) {
        // Only errors if the event loop is already closed
        self.proxy.send_event(ProxyMessage::TriggerExit).ok();
        self.handle.take().unwrap().join().unwrap();
    }
}

pub struct MemoryMappedGPU {
    state: Option<GPUState>,
}

impl MemoryMappedGPU {
    pub fn new() -> Box<Self> {
        Box::new(Self { state: None })
    }

    pub fn init(&mut self) {
        // Destroy existing window
        std::mem::drop(self.state.take());

        let (proxy_send, proxy_recv) = oneshot::channel();
        let handle = std::thread::spawn(move || gpu_thread(proxy_send));
        let proxy = proxy_recv
            .recv()
            .expect("Error getting EventLoopProxy for GPU");

        self.state = Some(GPUState {
            handle: Some(handle),
            proxy: proxy,
        });
    }
}

impl Memory for MemoryMappedGPU {
    fn probe(&self, _addr: u16) -> u16 {
        0
    }

    fn read(&mut self, addr: u16) -> u16 {
        0
    }

    fn write(&mut self, addr: u16, value: u16) {
        self.init();
    }

    fn len(&self) -> usize {
        2
    }
}

enum ProxyMessage {
    TriggerRedraw,
    TriggerExit,
}

fn gpu_thread(proxy_channel: Sender<EventLoopProxy<ProxyMessage>>) {
    let event_loop = EventLoopBuilder::with_user_event().build();
    proxy_channel.send(event_loop.create_proxy()).unwrap();

    let window = WindowBuilder::new()
        .build(&event_loop)
        .expect("Error creating window");
    let mut graphics_context =
        unsafe { GraphicsContext::new(&window, &window) }.expect("Error creating graphics context");

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::UserEvent(ProxyMessage::TriggerRedraw) => {
                window.request_redraw();
            }
            Event::UserEvent(ProxyMessage::TriggerExit) => {
                *control_flow = ControlFlow::Exit;
            }
            Event::RedrawRequested(window_id) if window_id == window.id() => {
                let (width, height) = {
                    let size = window.inner_size();
                    (size.width, size.height)
                };
                let buffer = (0..((width * height) as usize))
                    .map(|index| {
                        let y = (index as u32) / width;
                        let x = (index as u32) % width;
                        let red = x % 255;
                        let green = y % 255;
                        let blue = (x * y) % 255;

                        let color = blue | (green << 8) | (red << 16);

                        color
                    })
                    .collect::<Vec<_>>();

                graphics_context.set_buffer(&buffer, width as u16, height as u16);
            }
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                window_id,
            } if window_id == window.id() => {
                *control_flow = ControlFlow::Exit;
            }
            _ => {}
        }
    });
}
