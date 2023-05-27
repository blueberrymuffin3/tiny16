/*
'b000
*/
module alu (
    input clk,
    input [2:0] op,
    input [15:0] in1,
    in2,
    output [15:0] out,
    output reg [3:0] flags
);

  reg [15:0] result;
  assign out = result;
  reg flag_z, flag_c, flag_n, flag_v;
  wire [3:0] flags_unlatched;
  assign flags_unlatched = {flag_z, flag_c, flag_n, flag_v};

  always @(negedge clk) begin
    flags <= flags_unlatched;
  end

  // Intermediate shift results:
  wire is_shr;
  // TODO: Use in2[7] so that shift values can be loaded with ldli
  assign is_shr = in2[15];
  wire [3:0] shr_amt;
  assign shr_amt = in2[3:0];
  wire [3:0] shl_amt;
  assign shl_amt = 16 - in2[3:0];
  wire [15:0] shr;
  assign shr = in1 >> shr_amt;
  wire [15:0] shl;
  assign shl = in1 << shl_amt;

  always @(*) begin
    if (op == 0) begin
      {flag_c, result} = in1 + in2;
      // TODO: WTF
      flag_v = (((in1[14:0] + in2[14:0]) & (1 << 15)) >> 15) ^ flag_c;
    end else if (op == 1) begin
      {flag_c, result} = in1 - in2;
      // TODO: WTF
      flag_v = (((in1[14:0] - in2[14:0]) & (1 << 15)) >> 15) ^ flag_c;
    end else if (op == 2) begin
      result = in1 & in2;
      {flag_c, flag_v} = 0;
    end else if (op == 3) begin
      result = in1 | in2;
      {flag_c, flag_v} = 0;
    end else if (op == 4) begin
      result = is_shr ? shr : shl;
      flag_v = (is_shr ? shl : shr) != 0;
      flag_c = 0;
    end else if (op == 5) begin  // LDUI
      result = {in2[7:0], in2[7:0]};
      {flag_c, flag_v} = 0;
    end else begin
      result = 0;
      {flag_c, flag_v} = 0;
    end

    flag_z = result == 0;
    flag_n = result[15];
  end
endmodule
