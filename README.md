# tiny16
tiny16 is a simple 16-bit RISC cpu.

# Repo layout
```sh
/doc      # ISA Documentation
/fasmg    # Assembler and assembly programs
/t16emu   # tiny16 emulator written in rust
/t16vl    # 1st attempt Verilog tiny16 implimentation
/t16q     # 2nd attempt SystemVerilog tiny16 implimentation
```

# Getting Started
```sh
# Setup environment with nix-shell
tiny16$ nix-shell
# Build and launch hello world program
nix-shell:tiny16$ make run.t16emu.hello_world_printf
# Start the emulator
> c
# Stop the emulator
> q
```
