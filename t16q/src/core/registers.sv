`default_nettype none

module Registers (
    input         clk,
    input  [ 3:0] memory_index,
    input  [15:0] memory_load,
    output [15:0] memory_store,
    input         memory_load_en,
    input  [ 3:0] alu_rs1_i,
    output [15:0] alu_rs1,
    input  [ 3:0] alu_rs2_i,
    output [15:0] alu_rs2,
    input  [ 3:0] alu_rd_i,
    input  [15:0] alu_rd
);
  var logic [15:0] regs[15:0];

  assign memory_store = regs[memory_index];
  assign alu_rs1 = alu_rs1_i == 0 ? 16'b0 : regs[alu_rs1_i];
  assign alu_rs2 = alu_rs2_i == 0 ? 16'b0 : regs[alu_rs2_i];

  // always_ff @(posedge clk, negedge clk) begin
  //   if (memory_load_en) regs[memory_index] <= memory_load;
  //   if (alu_rd_i != 0) regs[alu_rd_i] <= alu_rd;
  // end
endmodule
