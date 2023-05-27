use crate::memory::Memory;

const CONSOLE_OFFSET_IO: u16 = 0;
const CONSOLE_OFFSET_INIT: u16 = 2;

pub struct MemoryMappedWGPU {}

impl MemoryMappedWGPU {
    pub fn new() -> Box<Self> {
        Box::new(Self {})
    }

    pub fn init(&mut self) {}
}

impl Memory for MemoryMappedWGPU {
    fn probe(&self, _addr: u16) -> u16 {
        0
    }

    fn read(&mut self, addr: u16) -> u16 {
        0
    }

    fn write(&mut self, addr: u16, value: u16) {}

    fn len(&self) -> usize {
        0
    }
}
