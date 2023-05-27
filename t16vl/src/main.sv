module main;
  reg clk, rst;
  always #10 clk = ~clk;

  core core (
      clk,
      rst
  );

  initial begin
    clk = 0;
    rst = 1;

    #55 rst = 0;

    // #(100_0) $finish;
  end  // initial begin
endmodule  // main
