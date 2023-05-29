`default_nettype none

typedef struct packed {
  bit uart_clk;
  bit uart_rx;
} MMIOIn;
typedef struct packed {bit uart_tx;} MMIOOut;

module MMU (
    input Clock clk,
    input w_en,
    input [15:0] addr,
    input [15:0] data_w,
    output [15:0] data_r,
    input MMIOIn mmio_in,
    output MMIOOut mmio_out
);
  always_comb begin
    rom_r_en  = 0;
    uart_r_en = 0;
    uart_w_en = 0;
    ram_r_en  = 0;
    ram_w_en  = 0;


    if (addr < 16'h7000) begin
      rom_r_en = !w_en;
      data_r   = rom_r;
    end else if (addr < 16'h7004) begin
      uart_r_en = !w_en;
      uart_w_en = w_en;
      data_r = uart_r;
    end else if (addr < 16'h8000) begin
      // Unused
      data_r = 0;
    end else begin
      ram_r_en = !w_en;
      ram_w_en = w_en;
      data_r   = ram_r;
    end
  end

  logic [15:0] rom_r;
  logic        rom_r_en;
  rom rom (
      .address(addr[14:1]),
      .clock(clk.ph0),
      .rden(rom_r_en),
      .q(rom_r)
  );

  logic [15:0] uart_r;
  logic        uart_r_en;
  logic        uart_w_en;
  MMUART uart (
      .addr(addr[1:1]),
      .clk(clk.ph0),
      .en_r(uart_r_en),
      .en_w(uart_w_en),
      .data_r(uart_r),
      .data_w(data_w),
      .uart_clk(mmio_in.uart_clk),
      .uart_rx(mmio_in.uart_rx),
      .uart_tx(mmio_out.uart_tx)
  );

  logic [15:0] ram_r;
  logic        ram_r_en;
  logic        ram_w_en;
  ram ram (
      .address(addr[14:1]),
      .clock(clk.ph0),
      .rden(ram_r_en),
      .wren(ram_w_en),
      .data(data_w),
      .q(ram_r)
  );
endmodule
