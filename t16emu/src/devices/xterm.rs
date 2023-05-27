use std::{
    fs::{File, OpenOptions},
    io::{Read, Write},
    os::fd::AsRawFd,
    process::Command,
};

use nix::{
    fcntl::OFlag,
    libc, pty,
    sys::{
        termios::{tcgetattr, tcsetattr, LocalFlags, SetArg},
    },
    unistd::{self, ForkResult},
};

use crate::memory::Memory;

const CONSOLE_OFFSET_IO: u16 = 0;
const CONSOLE_OFFSET_INIT: u16 = 2;

pub struct MemoryMappedConsoleXTerm {
    pts: Option<File>, // Dropping this causes xterm to exit
}

impl MemoryMappedConsoleXTerm {
    pub fn new() -> Box<Self> {
        Box::new(Self { pts: None })
    }

    // Based on code from
    // https://github.com/ArmageddonGames/ZQuestClassic/blob/5a65ea15a3b6aa95e273533f5bd3edc7f511a73d/src/LINUX_Console.cpp#L38
    // and https://github.com/TeamSPoon/swipl-devel-unstable/blob/d865dafa8c30a83ee8567ecbd02c83632d21ac64/src/pl-xterm.c#L240
    pub fn init(&mut self) {
        if let Some(_) = self.pts {
            return;
        }

        let pt: pty::PtyMaster = pty::posix_openpt(OFlag::O_RDWR).expect("Error creating pty");

        pty::grantpt(&pt).expect("Error granting pt");
        pty::unlockpt(&pt).expect("Error unlocking pt");

        let pts_name = pty::ptsname_r(&pt).expect("Error getting pts name");
        let mut pts = OpenOptions::new()
            .read(true)
            .write(true)
            .open(&pts_name)
            .unwrap();

        let mut termios = tcgetattr(pts.as_raw_fd()).expect("Error getting termios flags");
        termios.local_flags -= LocalFlags::ECHO;
        termios.local_flags -= LocalFlags::ICANON;
        termios.local_flags |= LocalFlags::IEXTEN;
        termios.control_chars[libc::VERASE] = b'\x08'; // V ERASE = backspace

        tcsetattr(pts.as_raw_fd(), SetArg::TCSANOW, &termios)
            .expect("Error updating termios flags");

        let mut command = Command::new("xterm");

        include_str!("xterm-solarized.txt")
            .lines()
            .for_each(|line| {
                command.args(["-xrm", line]);
            });

        command
            .env("TERM", "xterm-256color")
            .args(["-T", "t16emu console"])
            .args(["-fa", "Monospace", "-fs", "12"])
            .args(["-xrm", "XTerm*selectToClipboard: true"])
            .arg(format!("-S{}/{}", &pts_name, pt.as_raw_fd()));

        // "break" our connection to the child, preventing it from receiving SIGINT's
        if let ForkResult::Child = unsafe { unistd::fork() }.unwrap() {
            unsafe {
                libc::setsid();
            }
            command.spawn().ok();
            unsafe {
                libc::_exit(0);
            }
        }

        // Reads and ignore the "window id"
        loop {
            let mut buf = [0u8];
            pts.read_exact(&mut buf).unwrap();
            if buf[0] == b'\n' {
                break;
            }
        }

        // Disable blocking after clearing window id
        termios.control_chars[libc::VMIN] = 0;
        termios.control_chars[libc::VTIME] = 0;
        tcsetattr(pts.as_raw_fd(), SetArg::TCSADRAIN, &termios)
            .expect("Error updating termios flags");

        self.pts = Some(pts);
    }
}

impl Memory for MemoryMappedConsoleXTerm {
    fn probe(&self, _addr: u16) -> u16 {
        0
    }

    fn read(&mut self, addr: u16) -> u16 {
        match addr {
            CONSOLE_OFFSET_IO => {
                if let Some(pts) = &mut self.pts {
                    let mut buf = [0u8; 1];
                    if let Ok(len) = pts.read(&mut buf) {
                        if len > 0 {
                            // TODO: Unicode Support
                            return buf[0] as u16;
                        }
                    }
                }

                return 0xFFFF;
            }
            _ => 0,
        }
    }

    fn write(&mut self, addr: u16, value: u16) {
        match addr {
            CONSOLE_OFFSET_IO => {
                if let Some(pts) = &mut self.pts {
                    // UTF-16 mode:
                    // pts.write_all(String::from_utf16_lossy(&[value]).as_bytes())
                    // .expect("Error writing to xterm");

                    // Raw (UTF-8) mode:
                    pts.write_all(&[(value & 0xFF) as u8])
                    .expect("Error writing to xterm");
                }
            }
            CONSOLE_OFFSET_INIT => {
                self.init();
            }
            _ => {}
        }
    }

    fn len(&self) -> usize {
        4
    }
}
