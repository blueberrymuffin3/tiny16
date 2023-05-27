module mmu (
    input clk,
    input w_en,
    input [15:0] addr,
    input [15:0] data_w,
    output [15:0] data_r
);
  wire [15:0] data_rom;
  rom rom (
      addr[14:1],
      data_rom
  );

  wire [15:0] data_ram;
  reg [15:0] ram[0:'h3FFF];
  assign data_ram = ram[addr[14:1]];

  assign data_r   = addr[15] ? data_ram : data_rom;
  //  TODO: Memory Mapped IO

  always @(negedge clk) begin
    if (w_en && addr[15]) begin
      ram[addr[14:1]] <= data_w;
      //  TODO: Memory Mapped IO
    end
  end
endmodule


// 16kword ROM
module rom (
    input  [13:0] addr,
    output [15:0] data
);
  reg [256:0] ROM_FILENAME;
  reg [16:0] rom[0:'h3FFF];
  assign data = rom[addr];

`ifdef iverilog
  initial begin
    if (!$value$plusargs("rom=%s", ROM_FILENAME)) begin
      $display("ERROR: please specify +rom=path.hex to start.");
      $finish;
    end

    $readmemh(ROM_FILENAME, rom);

    $display("ROM file %s loaded", ROM_FILENAME);
  end
`endif
endmodule
