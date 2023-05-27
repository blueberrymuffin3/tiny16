module core (
    input clk,
    input rst
);
  reg rst_latched;

  reg [3:0] rs1_i;
  reg [3:0] rs2_i;
  reg [7:0] rs2_imm;
  reg [3:0] rd_i;
  reg [15:0] register_file[0:15];
  wire [15:0] inst_reg;
  assign inst_reg = register_file[0];
  wire [3:0] inst_op, inst_a, inst_b, inst_c;
  assign {inst_op, inst_a, inst_b, inst_c} = inst_reg;
  wire [15:0] rs1;
  assign rs1 = rs1_i == 0 ? 0 : register_file[rs1_i];
  wire [15:0] rs2;
  assign rs2 = rs2_i == 0 ? rs2_imm : register_file[rs2_i];

  always @(clk) begin
    if (rd_i != 0) begin
      register_file[rd_i] <= alu_out;
    end
    if (bus_mem_r_en && mem_reg_i != 0) begin
      register_file[mem_reg_i] <= bus_mem_r;
    end
  end

  wire [15:0] bus_mem_r;
  wire [15:0] bus_mem_w;
  assign bus_mem_w = register_file[mem_reg_i];
  reg bus_mem_w_en;
  reg bus_mem_r_en;
  reg [3:0] mem_reg_i;
  wire [15:0] bus_mem_addr;
  assign bus_mem_addr = alu_out;
  mmu mmu (
      .clk(clk),
      .w_en(bus_mem_w_en),
      .addr(bus_mem_addr),
      .data_w(bus_mem_w),
      .data_r(bus_mem_r)
  );

  task logstate;
`ifdef iverilog
    $display(
        "clk=%d, rst=%d, ir=%04x, pc=%04x      ALU: op=%d, [%x]=>%04x [%x %02x]=>%04x = %04x=>[%x] %04b      MEM: r:%x w:%x r[%x]<=>m[%04x]",
        clk, rst_latched, inst_reg, register_file[15], alu_op, rs1_i, rs1, rs2_i, rs2_imm, rs2,
        alu_out, rd_i, alu_flags, bus_mem_r_en, bus_mem_w_en, mem_reg_i, bus_mem_addr);
`endif
  endtask

  function [1:0] check_cond(input [3:0] check, input [3:0] flags);
    case (check >> 1)
      3'd0: check_cond = check[0] ^ (flags[3]);
      3'd1: check_cond = check[0] ^ (flags[2]);
      3'd2: check_cond = check[0] ^ (flags[1]);
      3'd3: check_cond = check[0] ^ (flags[0]);
      3'd4: check_cond = check[0] ^ (flags[2] && !flags[3]);
      3'd5: check_cond = check[0] ^ (flags[1] == flags[0]);
      3'd6: check_cond = check[0] ^ (!flags[3] && (flags[1] == flags[3]));
      3'd7: check_cond = check[0] ^ (1);
      default: check_cond = 0;
    endcase
  endfunction

  always @(clk) begin
    // $display("%04x", register_file[15]);

    if (rst_latched) begin
      alu_op <= 0;
      rd_i <= 15;
      rs1_i <= 0;
      rs2_i <= 0;
      rs2_imm <= 0;
      mem_reg_i <= 0;
      bus_mem_r_en <= 1;
      bus_mem_w_en <= 0;
    end else if (!clk) begin
      // Instruction Fetch
      alu_op <= 0;
      rd_i <= 15;
      rs1_i <= 15;
      rs2_i <= 0;
      rs2_imm <= 2;
      mem_reg_i = 0;
      bus_mem_r_en <= 1;
      bus_mem_w_en <= 0;
    end else if (inst_op <= 'h9) begin
      // Instruction Execute (ALU)
      alu_op <= inst_op >> 1;
      rd_i <= inst_a;
      rs1_i <= inst_b;  // PC
      rs2_i <= inst_op[0] ? inst_c : 0;
      rs2_imm <= inst_c;
      mem_reg_i <= 0;
      bus_mem_r_en <= 0;
      bus_mem_w_en <= 0;
    end else if (inst_op == 'hA) begin
      // LDLI
      alu_op <= 0;
      rd_i <= inst_a;
      rs1_i <= 0;
      rs2_i <= 0;
      rs2_imm <= {inst_b, inst_c};
      mem_reg_i <= 0;
      bus_mem_r_en <= 0;
      bus_mem_w_en <= 0;
    end else if (inst_op == 'hB) begin
      // LDUI
      alu_op <= 5;
      rd_i <= inst_a;
      rs1_i <= inst_a;
      rs2_i <= 0;
      rs2_imm <= {inst_b, inst_c};
      mem_reg_i <= 0;
      bus_mem_r_en <= 0;
      bus_mem_w_en <= 0;
    end else if (inst_op == 'hC) begin
      // LDR
      alu_op <= 0;
      rd_i <= 0;
      rs1_i <= inst_b;
      rs2_i <= 0;
      rs2_imm <= inst_c;
      mem_reg_i <= inst_a;
      bus_mem_r_en <= 1;
      bus_mem_w_en <= 0;
    end else if (inst_op == 'hD) begin
      // STR
      alu_op <= 0;
      rd_i <= 0;
      rs1_i <= inst_b;
      rs2_i <= 0;
      rs2_imm <= inst_c;
      mem_reg_i <= inst_a;
      bus_mem_r_en <= 0;
      bus_mem_w_en <= 1;
    end else if (inst_op == 'hE) begin
      // B
      alu_op <= 0;
      rd_i <= check_cond(inst_a, alu_flags) ? 15 : 0;  // 15 | 0
      rs1_i <= 15;
      rs2_i <= 0;
      rs2_imm <= {{8{inst_b[3]}}, inst_b, inst_c};
      mem_reg_i <= 0;
      bus_mem_r_en <= 0;
      bus_mem_w_en <= 0;
    end else if (inst_op == 'hF) begin
      // INT
      alu_op <= 1;
      rd_i <= 15;
      rs1_i <= 15;
      rs2_i <= 0;
      rs2_imm <= 2;
      mem_reg_i <= inst_a;
      bus_mem_r_en <= 0;
      bus_mem_w_en <= 1;

`ifdef iverilog
      #40 $finish;
`endif
    end

    logstate;
  end

  reg [ 2:0] alu_op;
  reg [15:0] alu_out;
  reg [ 3:0] alu_flags;
  alu alu (
      .clk(clk),
      .op(alu_op),
      .in1(rs1),
      .in2(rs2),
      .out(alu_out),
      .flags(alu_flags)
  );

  always @(posedge clk) begin
    rst_latched <= rst;
  end

  initial begin
    rst_latched <= 1;
  end
endmodule
