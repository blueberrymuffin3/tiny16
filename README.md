# tiny16
tiny16 is a simple 16-bit RISC cpu.

# Repo layout
```sh
/doc      # ISA Documentation
/fasmg    # Assembler and assembly programs
/t16emu   # tiny16 emulator written in rust
/t16vl    # 1st attempt Verilog tiny16 implimentation
/t16q     # 2nd attempt SystemVerilog tiny16 implimentation
/vsc-ext  # VSCode extension for syntax-highlighing .t16s and .t16inc files
```

# Getting Started
```sh
# Install the VSCode extension (linux)
$ ln -s $(pwd)/vsc-ext ~/.vscode/extensions/tiny16-vsc-0.0.1
# Setup environment with nix-shell
$ nix-shell
# Build and launch hello world program
nix-shell$ make run.t16emu.hello_world_printf
# Start the emulator
> c
# Stop the emulator
> q
```
