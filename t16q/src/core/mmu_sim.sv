`default_nettype none

module MMU (
    input Clock clk,
    input w_en,
    input [15:0] addr,
    input [15:0] data_w,
    output [15:0] data_r
);
  logic [15:0] data_rom;
  ROM rom (
      addr[14:1],
      data_rom
  );

  logic [15:0] ram['h4000];
  logic [15:0] data_ram;
  assign data_ram = ram[addr[14:1]];

  assign data_r   = addr[15] ? data_ram : data_rom;
  //  TODO: Memory Mapped IO

  always_ff @(posedge clk.ph0)
    if (w_en && addr[15]) begin
      ram[addr[14:1]] <= data_w;
      //  TODO: Memory Mapped IO
    end
endmodule


// 16kword ROM
module ROM (
    input  [13:0] addr,
    output [15:0] data
);
  logic [15:0] rom['h4000];
  assign data = rom[addr];
  // defparam .lpm_hint = "ENABLE_RUNTIME_MOD = YES, INSTANCE_NAME = rom";

`ifdef iverilog
  string ROM_FILENAME;
  initial begin
    if (!$value$plusargs("rom=%s", ROM_FILENAME)) begin
      $display("ERROR: please specify +rom=path.hex to start.");
      $finish;
    end

    $readmemh(ROM_FILENAME, rom);

    $display("ROM file %s loaded", ROM_FILENAME);
  end
`else
  initial begin
    $readmemh("../../fasmg/bin/hello_world_printf.hex", rom);
  end
`endif
endmodule
