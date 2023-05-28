from functools import reduce
from sys import stdout, stdin

DEPTH = 0x4000
print(f"DEPTH = {DEPTH};")
print(f"WIDTH = {16};")
print(f"ADDRESS_RADIX = HEX;")
print(f"DATA_RADIX = HEX;")
print(f"CONTENT")
print(f"BEGIN")

for addr in range(DEPTH):
  word = stdin.buffer.read(2)
  if len(word) == 2:
    pass
  elif len(word) == 0:
    word = b"\x00\x00"
  else:
    raise RuntimeError("Odd-sized .t16 file")

  word = int.from_bytes(word, 'little')
  
  print(f"{addr:04X}: {word:04X};")

print(f"END;")
