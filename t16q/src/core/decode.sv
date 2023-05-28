`default_nettype none

module Decode (
    input Clock clk,
    input [15:0] ir,
    input ALUFlags flags,

    output ALUOp alu_op,
    output [3:0] alu_rs1_i,
    output [3:0] alu_rs2_i,
    output [15:0] alu_imm,
    output alu_use_imm,
    output [3:0] alu_rd_i,

    output [3:0] mem_i,
    output       mem_w_en
);
  logic [3:0] op;
  logic [3:0] o1;
  logic [3:0] o2;
  logic [3:0] o3;
  assign {op, o1, o2, o3} = ir;

  function bit check_cond(input [3:0] check, input ALUFlags flags);
    case (check >> 1)
      3'd0: check_cond = check[0] ^ (flags.z);
      3'd1: check_cond = check[0] ^ (flags.c);
      3'd2: check_cond = check[0] ^ (flags.n);
      3'd3: check_cond = check[0] ^ (flags.v);
      3'd4: check_cond = check[0] ^ (flags.c && !flags.z);
      3'd5: check_cond = check[0] ^ (flags.n == flags.v);
      3'd6: check_cond = check[0] ^ (!flags.z && (flags.n == flags.z));
      3'd7: check_cond = check[0] ^ (1);
      default: check_cond = 0;
    endcase
  endfunction

  always_comb begin
    // Default NOP
    alu_op = ADD;
    alu_rs1_i = 4'h0;
    alu_rs2_i = 4'h0;
    alu_imm = 8'b0;
    alu_use_imm = 0;
    alu_rd_i = 4'h0;

    mem_i = 4'h0;
    mem_w_en = 0;


    if (clk.ph1) begin
      // Fetch
      alu_op = ADD;
      alu_rs1_i = 4'hF;  // PC
      alu_imm = 15'd2;
      alu_use_imm = 1;
      alu_rd_i = 4'hF;  // PC

      mem_i = 4'h0;  // IR
      mem_w_en = 0;
    end else begin
      case (op)
        4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
          // ALU Instructions
          alu_op = ALUOp'(op[3:1]);
          alu_rs1_i = o2;
          alu_rs2_i = o3;
          alu_imm = {12'b0, o3};
          alu_use_imm = !op[0];
          alu_rd_i = o1;
        end
        4'hA: begin
          // LDLI Instruction
          alu_op = ADD;
          alu_rs1_i = 4'h0;
          alu_imm = {8'b0, o2, o3};
          alu_use_imm = 1;
          alu_rd_i = o1;
        end
        4'hB: begin
          // LDUI Instruction
          alu_op = LDUI;
          alu_rs1_i = o1;
          alu_imm = {8'b0, o2, o3};
          alu_use_imm = 1;
          alu_rd_i = o1;
        end
        4'hC, 4'hD: begin
          // LDR/STR Instructions
          alu_op = ADD;
          alu_rs1_i = o2;
          alu_imm = {12'b0, o3};
          alu_use_imm = 1;
          alu_rd_i = 4'h0;

          mem_i = o1;
          mem_w_en = op[0];  // op == STR
        end
        4'hE: begin
          // B Instructions
          alu_op = ADD;
          alu_rs1_i = 4'hF;
          alu_imm = 16'(signed'({o2, o3}));
          alu_use_imm = 1;
          alu_rd_i = check_cond(o1, flags) ? 4'hF : 4'h0;
        end
        default: begin
          // NOP
        end
      endcase
    end
  end
endmodule
