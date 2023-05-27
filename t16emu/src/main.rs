use colored::*;
use nix::{sys::signal, unistd::Pid};
use std::{
    cmp::min,
    env,
    io::{self, Write},
    ops::RangeInclusive,
    sync::atomic::{AtomicBool, Ordering},
    time::Duration,
};

use crate::devices::xterm::MemoryMappedConsoleXTerm;
use crate::emulator::ProcessorState;
use crate::memory::{Memory, MemoryMapSection, MemoryRAM, MemoryROM};

mod devices;
mod emulator;
mod memory;

const REGISTER_NAMES: [&str; 16] = [
    "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11", "r12", "sp", "lr",
    "pc",
];

const DUMP_TOTAL: u16 = 10 * 2;
const DUMP_BEFORE: u16 = 5 * 2;
static INTERRUPT_FLAG: AtomicBool = AtomicBool::new(true);

const MAX_FREQ: f32 = 500e3f32;
const SLEEP_FOR: f32 = 1f32 / 30f32;
const SLEEP_EVERY: isize = (SLEEP_FOR * MAX_FREQ) as isize;

fn main() {
    ctrlc::set_handler(move || {
        if INTERRUPT_FLAG.swap(true, Ordering::Relaxed) {
            signal::kill(Pid::this(), signal::SIGTERM).unwrap();
        };
    })
    .expect("Error setting Ctrl-C handler");

    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        println!("Usage: {} <rom.t16 path>", args[0])
    }

    let rom_path = &args[1];

    let mut state: ProcessorState = ProcessorState::new(vec![
        MemoryMapSection::new(
            0,
            MemoryROM::from_file(rom_path).expect("Error reading ROM"),
        ),
        MemoryMapSection::new(0x7000, MemoryMappedConsoleXTerm::new()),
        MemoryMapSection::new(0x8000, MemoryRAM::new(0x8000)),
    ]);

    let mut cmd = String::new();
    let mut instruction_count = 0isize;

    loop {
        if INTERRUPT_FLAG.load(Ordering::Relaxed) {
            update_screen(&state);
            io::stdin().read_line(&mut cmd).unwrap();

            if cmd.len() < 1 {
                println!();
                break;
            } else if cmd.as_bytes()[0] == 'c' as u8 {
                INTERRUPT_FLAG.store(false, Ordering::Relaxed);
            } else if cmd.as_bytes()[0] == 'q' as u8 {
                break;
            }

            cmd.clear();
        }

        instruction_count += 1;
        if instruction_count % SLEEP_EVERY == 0 {
            std::thread::sleep(Duration::from_secs_f32(SLEEP_FOR));
        }

        if emulator::exec_inst(&mut state) {
            INTERRUPT_FLAG.store(true, Ordering::Relaxed);
        }
    }

    println!(
        "Executed {instruction_count} instruction, using at most {} bytes of stack space",
        state.registers.get_stack_water_mark()
    );
}

fn print_heading(s: &str, width: usize) {
    println!("{:-^width$}", format!("  {}  ", s).blue().bold());
}

fn update_screen(state: &ProcessorState) {
    // crossterm::execute!(
    //     io::stdout(),
    //     crossterm::terminal::Clear(ClearType::All),
    //     crossterm::cursor::MoveTo(0, 0),
    // ).unwrap();

    println!();
    print_heading("Registers", 53);
    for i in 0..16 {
        print!(
            "{} {}{}{} ",
            "|".dimmed(),
            format!("{:4}", REGISTER_NAMES[i as usize]).green(),
            "0x".dimmed(),
            format!("{:04X}", state.registers.read(i)),
        );
        if i % 4 == 3 {
            println!("{}", "|".dimmed());
        }
    }

    print_heading("Flags", 14);
    print!("{}", "|".dimmed());
    for (name, value) in [
        ("z", state.flags.z),
        ("c", state.flags.c),
        ("n", state.flags.n),
        ("v", state.flags.v),
    ] {
        let c = if value {
            name.to_ascii_uppercase().green().bold()
        } else {
            name.to_ascii_lowercase().red().dimmed()
        };
        print!(" {} ", c);
    }
    println!("{}", "|".dimmed());

    print_heading("Code", 53);
    let dump_start = min(
        0xFFFF - DUMP_TOTAL,
        state.registers.pc().saturating_sub(DUMP_BEFORE),
    );
    code_dump(state, dump_start..=dump_start + DUMP_TOTAL);
    println!();
    print!(" > ");
    io::stdout().flush().unwrap();
}

fn code_dump(state: &ProcessorState, range: RangeInclusive<u16>) {
    for addr in range.step_by(2) {
        let is_current = state.registers.pc() == addr;

        let addr_s = format!("{:04X}", addr).bright_blue();
        let value = state.memory.probe(addr);
        let value = format!("{:04X}", value).bright_blue();

        let debug_text = state.memory.debug_text(addr).unwrap_or("");
        let mut lines = debug_text.lines();
        let mut debug_text_indented = lines.next().unwrap_or("").to_owned();
        for line in lines {
            debug_text_indented += "\n";
            debug_text_indented += &" ".repeat(12);
            debug_text_indented += line;
        }

        let line = format!("{addr_s}: {value}  {debug_text_indented}");

        if is_current {
            println!("{}", line);
        } else {
            println!("{}", line.dimmed());
        }
    }
}
