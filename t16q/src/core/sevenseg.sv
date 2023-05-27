`default_nettype none

module SevenSegWord (
    input  var [15:0] word,
    output var [ 7:0] digit0,
    output var [ 7:0] digit1,
    output var [ 7:0] digit2,
    output var [ 7:0] digit3
);
  SevenSegDigit hex0 (
      word[3:0],
      digit0
  );
  SevenSegDigit hex1 (
      word[7:4],
      digit1
  );
  SevenSegDigit hex2 (
      word[11:8],
      digit2
  );
  SevenSegDigit hex3 (
      word[15:12],
      digit3
  );
endmodule

module SevenSegDigit (
    input  var [3:0] nybble,
    output var [7:0] digitOut
);
  var [6:0] digit;
  assign digitOut = ~{1'b0, digit[0], digit[1], digit[2], digit[3], digit[4], digit[5], digit[6]};

  always_comb case (nybble)
    'h0: digit = 7'b111111_0;
    'h1: digit = 7'b011000_0;
    'h2: digit = 7'b110110_1;
    'h3: digit = 7'b111100_1;
    'h4: digit = 7'b011001_1;
    'h5: digit = 7'b101101_1;
    'h6: digit = 7'b101111_1;
    'h7: digit = 7'b111000_0;
    'h8: digit = 7'b111111_1;
    'h9: digit = 7'b111101_1;
    'hA: digit = 7'b111011_1;
    'hB: digit = 7'b001111_1;
    'hC: digit = 7'b100111_0;
    'hD: digit = 7'b011110_1;
    'hE: digit = 7'b100111_1;
    'hF: digit = 7'b100011_1;
    default: digit = 7'b0;
  endcase
endmodule
