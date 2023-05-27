`define GPU_MODE_FHD


module GPU (
    input clk,

    output [11:0] rgb,
    output        hs,
    output        vs
);
  parameter int h_divide = 2;

  // 1920x1080
  parameter int h_active = 1920 / h_divide;
  parameter int h_fp = 88 / h_divide;
  parameter int h_sync = 44 / h_divide;
  parameter int h_bp = 148 / h_divide;

  parameter int v_active = 1080;
  parameter int v_fp = 4;
  parameter int v_sync = 5;
  parameter int v_bp = 36;


  parameter int h_sync_start = h_active + h_fp;
  parameter int h_sync_end = h_sync_start + h_sync;
  parameter int h_total = h_active + h_fp + h_sync + h_bp;

  parameter int v_sync_start = v_active + v_fp;
  parameter int v_sync_end = v_sync_start + v_sync;
  parameter int v_total = v_active + v_fp + v_sync + v_bp;


  bit [11:0] x;
  bit [11:0] y;
  bit show;

  bit [7:0] counter;

  always_ff @(posedge clk) begin
    if (x < h_active && y < v_active) begin
      if (x < 8 || y < 16 || x >= h_active - 8 || y >= v_active - 16) rgb <= (x[1] ^ y[2] ^ counter[5]) ? 12'hFFF : 12'h000;
      else rgb <= 12'h333;
    end else begin
      rgb <= 12'b0;
    end

    hs <= x >= h_sync_start && x < h_sync_end;
    vs <= y >= v_sync_start && y < v_sync_end;

    if (x == h_total) begin
      x <= 0;
      if (y == v_total) begin
        y <= 0;
        counter <= counter + 1;
      end else begin
        y <= y + 1;
      end
    end else begin
      x <= x + 1;
    end
  end
endmodule
