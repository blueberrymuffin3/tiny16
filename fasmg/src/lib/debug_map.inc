include 'xcalm.inc'

define DebugMap? DebugMap

macro print_location
  local stack, v
  v = __line__

  db __file__, ":"

  stack = 15
  while v > 0
    stack = stack * 16 + v mod 10
    v = v / 10
  end while

  while stack <> 15
    db stack mod 16 + 0x30
    stack = stack / 16
  end while
end macro

namespace DebugMap

  ON = 0
  ADDR_SIZE = 16
  ADDR_LENGTH = ADDR_SIZE shr 2

  MAX_BYTES_IN_ROW = 4

  virtual at 0
    HexDigits:: db '0123456789ABCDEF'
  end virtual

  virtual as 'dbg'
    Text::
  end virtual

  define base
  define address

  calminstruction hex_nibble digit*
    compute digit, 0FFh and '0123456789ABCDEF' shr (digit*8)
    asm db digit
  end calminstruction

  calminstruction display_hex_word value
    compute value, value
    local   digit
    compute digit, (value shr 12) and 0Fh
    call    hex_nibble, digit
    compute digit, (value shr 8) and 0Fh
    call    hex_nibble, digit
    compute digit, (value shr 4) and 0Fh
    call    hex_nibble, digit
    compute digit, value and 0Fh
    call    hex_nibble, digit
  end calminstruction

  retaincomments
  calminstruction ? line&
      local asm_line, comment
      arrange asm_line, line
      match ;#comment, asm_line
      jyes skip_line
      match ; comment, asm_line
      jyes skip_line
      match asm_line#;#comment, asm_line
      match asm_line ; comment, asm_line
      match asm_line ;#comment, asm_line
      match asm_line#; comment, asm_line
  
      assemble asm_line

    skip_line:
      check	ON
      jno	done

      stringify line

      check	$$ eq base
      jyes	area_ok
      compute base, $$
      compute address, $
    area_ok:

      local	bytes, counter, digit

      compute bytes, $ - address
      check	$ - bytes >= $$ & bytes >= 0
      jyes	size_ok
      compute bytes, $ - $$
    size_ok:
      asm	virtual Text
        call display_hex_word, address
        asm db '|'
        asm print_location
        asm db '  ', line, 0x0A
      asm	end virtual

      compute address, $
    done:
  end calminstruction
  removecomments
end namespace

calminstruction nodbg?!
  compute DebugMap.ON, 0
  asm removecomments
end calminstruction

calminstruction dbg?!
  asm retaincomments
  compute DebugMap.ON, 1
  compute DebugMap.base, $$
  compute DebugMap.address, $
end calminstruction

postpone
  nodbg
end postpone
