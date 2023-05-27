# THIS FILE IS OUT OF DATE

# Registers (2 special, 14 real)
- Program Counter (pc) (shifted right one for better jump range?)
- Flags (fl): Zero Z, Cary C, Negative N, Overflow V
- Zero (rz)
- Generic: sp, lr


# Instruction Encoding
```
CCCC OOOO OOOO OOOO
C: Opcode
O: Operands
```


# Opcodes
## Standard (arithmetic) Opcodes
Minimum:
- Add
- Subtract
- AND
- OR
- XOR

If Space:
- adc
- sbc
- Negate
- SLU (shift left unsigned)
- SRU (shift right unsigned)
- SRS (shift right signed/arithmetic)
- Load Immediate (8 bits)
- Load Upper Immediate

- NAND
- NOR
- XNOR


## Load and Store
- Load
- Store

```
CCCC VVVV AAAA OOOO
V: Value Register
A: Address Register
O: Offset immediate
```

## Conditional Move
- Conditional Move
```
CCCC DDDD SSSS FFFF
C: Opcode
D: Destination
S: Source
F: Flags: Steal from arm!
```

| cond | Name  | Meaning                             | Condition flags   |
|------|-------|-------------------------------------|-------------------|
| 0000 | EQ    | Equal                               | Z == 1            |
| 0001 | NE    | Not equal                           | Z == 0            |
| 0010 | CS/HS | Carry set / Unsigned higher or same | C == 1            |
| 0011 | CC/LO | Carry clear / Unsigned lower        | C == 0            |
| 0100 | MI    | Minus, negative                     | N == 1            |
| 0101 | PL    | Plus, positive or zero              | N == 0            |
| 0110 | VS    | Overflow                            | V == 1            |
| 0111 | VC    | No overflow                         | V == 0            |
| 1000 | HI    | Unsigned higher                     | C == 1 and Z == 0 |
| 1001 | LS    | Unsigned lower or same              | C == 0 or Z == 1  |
| 1010 | GE    | Signed 5nop)                         |                   |

````
Optimized Condition Encoding: ABCD
A=0:
  if flags[BC] = D

ABC=101:
  N^V = ~D

ABC=110:
  N^V = D AND Z = D

ABC=111:
  if D
````

## Conditional move alternative: Conditional Relative Jump
```
CCCC FFFF OOOO OOOO
C: Opcode
F: Flags: Steal from arm!
O: Signed offset (in words)
```

- Con: no conditional move for other regs
- Con: First nybble not always destination register
- Pro: reduced register pressure from jump targets
- Pro: reduced instructions loading jump targets
