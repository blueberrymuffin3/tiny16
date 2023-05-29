`default_nettype none

module Core #(
    int CLKDIV = 0
) (
    input clkin,
    input reset,
    input MMIOIn mmio_in,
    output MMIOOut mmio_out,

    output [15:0] debug_d,
    output [ 3:0] debug_rd,
    output [ 3:0] debug_mi,
    output [ 9:0] debug_leds
);
  Clock clk;
  ClockGen #(CLKDIV) clkgen (
      clkin,
      clk
  );

  // assign debug_d = alu_d;
  assign debug_d = (clk.ph0 && (clk.ph1 || mem_i != 0)) ? mem_r : alu_d;
  assign debug_mi = mem_i;
  assign debug_rd = alu_rd_i;
  assign debug_leds[9] = clk.ph1;
  assign debug_leds[8] = clk.ph0;
  assign debug_leds[7] = mem_w_en;
  assign debug_leds[6] = !mmio_out.uart_tx;
  assign debug_leds[5] = mmio_out.uart_tx;
  assign debug_leds[4:1] = 4'(alu_flags_l);
  assign debug_leds[0] = reset_l;

  logic reset_l = 1;
  always_ff @(posedge clk.ph1) begin
    reset_l <= reset;
  end


  ALUOp alu_op;
  logic [15:0] alu_s1;
  logic [15:0] alu_s2;
  logic [15:0] alu_d;
  ALUFlags alu_flags_nl;
  ALUFlags alu_flags_l;
  always_ff @(negedge clk.ph0) begin
    // Store *before* ph1 updates
    if (!clk.ph1) alu_flags_l <= alu_flags_nl;
  end

  ALU alu (
      .op(alu_op),
      .s1(alu_s1),
      .s2(alu_s2),
      .d(alu_d),
      .flags(alu_flags_nl)
  );

  logic [ 3:0] mem_i;
  logic [15:0] reg_ir;
  logic [15:0] reg_rs1;
  logic [15:0] reg_rs2;
  Registers registers (
      .clk(clk),

      .ir(reg_ir),

      .memory_index(mem_i),
      .memory_load(mem_r),
      .memory_store(mem_w),
      .memory_load_en(!mem_w_en),

      .alu_rs1_i(alu_rs1_i),
      .alu_rs1(reg_rs1),
      .alu_rs2_i(alu_rs2_i),
      .alu_rs2(reg_rs2),
      .alu_rd_i(alu_rd_i),
      .alu_rd(alu_d)
  );


  logic        mem_w_en;
  logic [15:0] mem_w;
  logic [15:0] mem_r;
  MMU mmu (
      .clk(clk),
      .w_en(mem_w_en),
      .addr(alu_d),
      .data_w(mem_w),
      .data_r(mem_r),
      .mmio_in(mmio_in),
      .mmio_out(mmio_out)
  );


  logic [15:0] reg_ir_or_reset;
  // "B 0" => "SUBI PC, R0, 2" => 0x2F02
  assign reg_ir_or_reset = reset_l ? 16'h2F02 : reg_ir;

  logic [3:0] alu_rs1_i;
  logic [3:0] alu_rs2_i;
  logic [15:0] alu_imm;
  logic       alu_use_imm;
  logic [3:0] alu_rd_i;

  Decode decode (
      .clk(clk),
      .ir(reg_ir_or_reset),
      .flags(alu_flags_l),
      .alu_op(alu_op),
      .alu_rs1_i(alu_rs1_i),
      .alu_rs2_i(alu_rs2_i),
      .alu_imm(alu_imm),
      .alu_use_imm(alu_use_imm),
      .alu_rd_i(alu_rd_i),
      .mem_i(mem_i),
      .mem_w_en(mem_w_en)
  );

  assign alu_s1 = reg_rs1;
  assign alu_s2 = alu_use_imm ? alu_imm : reg_rs2;
endmodule
