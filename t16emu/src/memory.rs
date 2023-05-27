use byteorder::{LittleEndian, ReadBytesExt};
use rand::Fill;
use std::{
    fs::File,
    io::{self, BufRead, BufReader},
    path::Path,
};

pub trait Memory {
    fn probe(&self, addr: u16) -> u16;
    fn read(&mut self, addr: u16) -> u16;
    fn write(&mut self, addr: u16, value: u16);
    fn debug_text(&self, _addr: u16) -> Option<&str> {
        None
    }
    fn len(&self) -> usize;
}

pub struct MemoryMapSection {
    offset: u16,
    contents: Box<dyn Memory>,
}

impl MemoryMapSection {
    pub fn new(offset: u16, contents: Box<dyn Memory>) -> Self {
        if offset as usize + contents.len() > 0x10000 {
            panic!("Memory section overflows available memory");
        }

        Self { offset, contents }
    }
}

pub struct MemoryMap {
    sections: Vec<MemoryMapSection>,
}

impl MemoryMap {
    pub fn new(mut sections: Vec<MemoryMapSection>) -> Self {
        sections.sort_unstable_by_key(|s| s.offset);

        for sections in sections.windows(2) {
            if sections[0].offset + (sections[0].contents.len() as u16) > sections[1].offset {
                panic!("Overlapping memory sections found")
            }
        }

        Self { sections }
    }

    fn resolve_addr(section: &MemoryMapSection, addr: u16) -> Option<u16> {
        if section.contents.len() < 2 {
            return None;
        }

        if addr >= section.offset && addr <= section.offset + (section.contents.len() - 2) as u16 {
            Some(addr - section.offset)
        } else {
            None
        }
    }
}

fn panic_if_unaligned(addr: u16, verb: &str) {
    if addr & 1 != 0 {
        panic!("Unaligned memory {verb} @ {addr:04X}");
    }
}

impl Memory for MemoryMap {
    fn probe(&self, addr: u16) -> u16 {
        panic_if_unaligned(addr, "probe");

        for section in &self.sections {
            if let Some(section_addr) = MemoryMap::resolve_addr(section, addr) {
                return section.contents.probe(section_addr);
            }
        }

        return 0;
    }

    fn read(&mut self, addr: u16) -> u16 {
        panic_if_unaligned(addr, "read");

        for section in &mut self.sections {
            if let Some(section_addr) = MemoryMap::resolve_addr(section, addr) {
                return section.contents.read(section_addr);
            }
        }

        return 0;
    }

    fn write(&mut self, addr: u16, value: u16) {
        panic_if_unaligned(addr, "write");

        for section in &mut self.sections {
            if let Some(section_addr) = MemoryMap::resolve_addr(section, addr) {
                section.contents.write(section_addr, value);
                break;
            }
        }
    }

    fn debug_text(&self, addr: u16) -> Option<&str> {
        if addr & 1 != 0 {
            panic!("Unaligned memory write");
        }

        for section in &self.sections {
            if let Some(section_addr) = MemoryMap::resolve_addr(section, addr) {
                return section.contents.debug_text(section_addr);
            }
        }

        None
    }

    fn len(&self) -> usize {
        0x10000
    }
}

pub struct MemoryRAM {
    data: Box<[u16]>,
}

impl MemoryRAM {
    pub fn new(size: usize) -> Box<Self> {
        let mut rng = rand::thread_rng();

        let mut data = vec![0u16; size / 2];
        data.try_fill(&mut rng).unwrap();

        Box::new(Self { data: data.into() })
    }
}

impl Memory for MemoryRAM {
    fn probe(&self, addr: u16) -> u16 {
        self.data[(addr / 2) as usize]
    }

    fn read(&mut self, addr: u16) -> u16 {
        return self.probe(addr);
    }

    fn write(&mut self, addr: u16, value: u16) {
        self.data[(addr / 2) as usize] = value;
    }

    fn len(&self) -> usize {
        self.data.len() * 2
    }
}

pub struct MemoryROM {
    data: Box<[u16]>,
    debug_text_map: Option<Box<[Option<String>]>>,
}

impl MemoryROM {
    pub fn from_file(path: &str) -> io::Result<Box<Self>> {
        let mut file = File::open(path)?;
        let file_meta = file.metadata()?;
        let word_count = (file_meta.len() / 2) as usize;
        let mut buffer = vec![0u16; word_count];
        file.read_u16_into::<LittleEndian>(&mut buffer)?;

        println!("Loaded {} words from ROM", word_count);

        let debug_text = MemoryROM::load_debug_symbols(path, word_count);
        if let Err(err) = &debug_text {
            println!("Error loading debug text: {}", err);
        }

        Ok(Box::new(Self {
            data: buffer.into(),
            debug_text_map: debug_text.ok(),
        }))
    }

    fn load_debug_symbols(path: &str, word_count: usize) -> io::Result<Box<[Option<String>]>> {
        let dbg_path = Path::new(path).with_extension("dbg");
        let file = File::open(dbg_path)?;
        let reader = BufReader::new(file);

        let mut dbg_text = vec![None; word_count].into_boxed_slice();

        for line in reader.lines() {
            let line = line?;
            let Some((addr_str, text)) = line.split_once("|") else {
                print!("Invalid line {:?}", line); continue;
            };
            let Ok(addr) = u16::from_str_radix(addr_str, 16) else {
                print!("Invalid address {:?}", addr_str); continue;
            };

            let index = (addr / 2) as usize;

            if let Some(line) = dbg_text.get_mut(index) {
                match line {
                    Some(prev) => {
                        *prev += "\n";
                        *prev += text;
                    }
                    None => *line = Some(text.to_owned()),
                }
            }
        }

        Ok(dbg_text)
    }
}

impl Memory for MemoryROM {
    fn probe(&self, addr: u16) -> u16 {
        self.data[(addr / 2) as usize]
    }

    fn read(&mut self, addr: u16) -> u16 {
        return self.probe(addr);
    }

    fn write(&mut self, _addr: u16, _value: u16) {
        // Ignore writes to ROM
    }

    fn debug_text(&self, addr: u16) -> Option<&str> {
        let Some(map) = &self.debug_text_map else {
            return None;
        };

        map[(addr / 2) as usize].as_deref()
    }

    fn len(&self) -> usize {
        self.data.len() * 2
    }
}
