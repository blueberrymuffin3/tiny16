typedef enum bit [2:0] {
  ADD,
  SUB,
  AND,
  XOR,
  SHR,
  LDUI
} ALUOp;

typedef struct {
  bit z;
  bit c;
  bit n;
  bit v;
} Flags;

module ALU (
    input ALUOp op,
    input [15:0] s1,
    input [15:0] s2,
    output [15:0] d,
    output Flags flags
);

  logic [16:0] result;
  assign d = result[15:0];

  assign flags.z = result[15:0] == 0;
  assign flags.c = result[16];
  assign flags.n = result[15];
  assign flags.v = (s1[15] == s2[15]) && (result[15] ^ s1[15]);

  always_comb
    case (op)
      ADD: result = s1 + s2;
      SUB: result = s1 - s2;
      AND: result = s1 & s2;
      XOR: result = s1 ^ s2;
      SHR: result = 0;
      LDUI: result = {s2[7:0], s1[7:0]};
      default: result = 0;
    endcase
endmodule
