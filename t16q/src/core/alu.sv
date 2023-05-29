`default_nettype none

typedef enum bit [2:0] {
  ADD,
  SUB,
  AND,
  XOR,
  SHR,
  LDUI
} ALUOp;

typedef struct packed {
  bit z;
  bit c;
  bit n;
  bit v;
} ALUFlags;

module ALU (
    input ALUOp op,
    input [15:0] s1,
    input [15:0] s2,
    output [15:0] d,
    output ALUFlags flags
);

  logic [16:0] result;
  assign d = result[15:0];

  assign flags.z = result[15:0] == 0;
  assign flags.c = result[16];
  assign flags.n = result[15];
  assign flags.v = ((s1[15] == s2[15]) ^ (op == SUB)) && (result[15] ^ s1[15]);

  always_comb
    case (op)
      ADD: result = s1 + s2 + 0;
      SUB: result = s1 - s2 + 0;
      AND: result = s1 & s2;
      XOR: result = s1 ^ s2;
      SHR: result = shr(s1, s2);
      LDUI: result = {s2[7:0], s1[7:0]};
      default: result = 0;
    endcase

  function automatic [16:0] shr(input [15:0] s1, input [15:0] s2);
    var [15:0] overflow; // TODO: Calculate
    var [15:0] res;
    var [3:0] shift = s2[3:0];
    if (!s2[15]) begin
      {res, overflow} = {s1, 16'b0} >> shift;
    end else begin
      {overflow, res} = {16'b0, s1} << 4'(-shift);
    end
    shr = {overflow != 0, res};
  endfunction
endmodule
