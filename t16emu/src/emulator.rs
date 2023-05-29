use rand::Rng;

use crate::memory::{Memory, MemoryMap, MemoryMapSection};

#[derive(Default)]
pub struct Flags {
    pub z: bool,
    pub c: bool,
    pub n: bool,
    pub v: bool,
}

impl Flags {
    pub fn from_value(value: u16, carry: bool, overflow: bool) -> Self {
        return Self {
            c: carry,
            z: value == 0,
            n: (value as i16).is_negative(),
            v: overflow,
        };
    }
}

pub struct Registers {
    data: [u16; 16],
    stack_water_mark: u32,
}

impl Registers {
    const INDEX_ZERO: u16 = 0;
    const INDEX_SP: u16 = 13;
    const INDEX_PC: u16 = 15;

    pub fn new() -> Self {
        let mut rng = rand::thread_rng();
        let mut data = [0u16; 16];
        rng.fill(&mut data);
        data[Registers::INDEX_ZERO as usize] = 0;
        data[Registers::INDEX_PC as usize] = 0;

        Self {
            data,
            stack_water_mark: 0,
        }
    }

    pub fn pc(&self) -> u16 {
        self.read(Registers::INDEX_PC)
    }

    pub fn pc_write(&mut self, value: u16) {
        self.write(Registers::INDEX_PC, value);
    }

    pub fn read(&self, addr: u16) -> u16 {
        self.data[addr as usize]
    }

    pub fn write(&mut self, addr: u16, value: u16) {
        match addr {
            Registers::INDEX_ZERO => {}
            Registers::INDEX_SP => {
                let usage = match value {
                    0 => 0,
                    _ => 0x10000 - (value as u32),
                };
                self.stack_water_mark = self.stack_water_mark.max(usage);
                self.data[addr as usize] = value;
            }
            _ => {
                self.data[addr as usize] = value;
            }
        }
    }

    pub fn get_stack_water_mark(&self) -> u32 {
        return self.stack_water_mark;
    }
}

pub struct ProcessorState {
    pub memory: MemoryMap,
    pub registers: Registers,
    pub flags: Flags,
}

impl ProcessorState {
    pub fn new(memory: Vec<MemoryMapSection>) -> Self {
        Self {
            memory: MemoryMap::new(memory),
            registers: Registers::new(),
            flags: Default::default(),
        }
    }
}

pub fn exec_inst(state: &mut ProcessorState) -> bool {
    let inst = state.memory.read(state.registers.pc());

    let opcode = inst >> 12 & 0xF;
    let i1 = inst >> 8 & 0xF;
    let i2 = inst >> 4 & 0xF;
    let i3 = inst >> 0 & 0xF;
    let imm8 = inst & 0xFF;
    let imm8s = imm8 as i8 as i16;
    let addr = state.registers.read(i2).wrapping_add(i3);

    // TODO: Rewrite all instructions to use ALU (handles flags automatically!)
    let mut return_value = false;
    match opcode {
        0x0..=0x9 => {
            let a = state.registers.read(i2);
            let b = if opcode & 1 == 0 {
                i3
            } else {
                state.registers.read(i3)
            };
            let (ret, flags) = alu_operation(opcode, a, b);
            state.flags = flags;
            state.registers.write(i1, ret);
        }
        0xA => {
            // LDI
            let value = imm8;
            state.registers.write(i1, value);
            state.flags = Flags::from_value(value, false, false);
        }
        0xB => {
            // LUI
            let value = imm8 << 8 | (state.registers.read(i1) & 0xFF);
            state.registers.write(i1, value);
            state.flags = Flags::from_value(value, false, false);
        }
        0xC => {
            // LDR
            // TODO: Partly Incorrect flags
            state.flags = Flags::from_value(addr, false, false);
            let value = state.memory.read(addr);
            state.registers.write(i1, value);
        }
        0xD => {
            // STR
            // TODO: Partly Incorrect flags
            state.flags = Flags::from_value(addr, false, false);
            state.memory.write(addr, state.registers.read(i1));
        }
        0xE => {
            // CMOV
            // if check_condition(&state.flags, i3) {
            //     state.registers.write(i1, state.registers.read(i2));
            // }
            // B
            if check_condition(&state.flags, i1) {
                state
                    .registers
                    .pc_write(state.registers.pc().wrapping_add_signed(imm8s))
            };
        }
        0xF => {
            // INT
            println!("INT Called");
            return_value = true;
        }
        0x10.. => panic!(),
    };

    state
        .registers
        .pc_write(state.registers.pc().wrapping_add(2));

    return_value
}

fn alu_operation(opcode: u16, a: u16, b: u16) -> (u16, Flags) {
    let ret: u16;
    let overflow_unsigned: bool;
    let overflow_signed: bool;

    match opcode & !1 {
        0x0 => {
            (ret, overflow_unsigned) = a.overflowing_add(b);
            overflow_signed = (a as i16).overflowing_add(b as i16).1;
        }
        0x2 => {
            (ret, overflow_unsigned) = a.overflowing_sub(b);
            overflow_signed = (a as i16).overflowing_sub(b as i16).1;
        }
        0x4 => {
            ret = a & b;
            overflow_unsigned = false;
            overflow_signed = false;
        }
        0x6 => {
            ret = a ^ b;
            overflow_unsigned = false;
            overflow_signed = false;
        }
        0x8 => {
            (ret, overflow_unsigned) = alu_overflow_shr(a, b as i16);
            overflow_signed = overflow_unsigned;
        }
        _ => panic!(),
    };
    // TODO: differentiate c and v: https://stackoverflow.com/a/6265950
    (
        ret,
        Flags::from_value(ret, overflow_unsigned, overflow_signed),
    )
}

fn alu_overflow_shr(a: u16, b: i16) -> (u16, bool) {
    let (res, overflow);
    if b > 0 {
        res = a >> b;
        overflow = res << b != a;
    } else {
        res = a << -b;
        overflow = res >> -b != a;
    }

    (res, overflow)
}

fn check_condition(flags: &Flags, condition: u16) -> bool {
    let ret = match condition >> 1 {
        0 => flags.z,
        1 => flags.c,
        2 => flags.n,
        3 => flags.v,
        4 => flags.c && !flags.z,
        5 => flags.n == flags.v,
        6 => !flags.z && (flags.n == flags.z),
        7 => true,
        8.. => panic!(),
    };

    if condition & 0x1 != 0 {
        !ret
    } else {
        ret
    }
}
