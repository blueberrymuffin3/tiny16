`default_nettype none

module MMU (
    input Clock clk,
    input w_en,
    input [15:0] addr,
    input [15:0] data_w,
    output [15:0] data_r
);
  logic is_rom;
  assign is_rom = !addr[15];

  logic [15:0] read_rom;
  logic [15:0] read_ram;
  assign data_r = is_rom ? read_rom : read_ram;

  rom rom(
    .address(addr[14:1]),
    .clock(clk.ph0),
    .rden(is_rom),
    .q(read_rom)
  );

  ram ram(
    .address(addr[14:1]),
    .clock(clk.ph0),
    .rden(!is_rom),
    .wren(!is_rom && w_en),
    .data(data_w),
    .q(read_ram)
  );
endmodule
