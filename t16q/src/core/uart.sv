`default_nettype none

module MMUART (
    input [0:0] addr,
    input clk,
    input en_r,
    input en_w,
    output var [15:0] data_r,
    input [15:0] data_w,
    input uart_clk,
    input uart_rx,
    output uart_tx
);
  always_ff @(posedge clk) begin
    if (en_r) begin
      data_r <= 0;
      if (addr == 0) data_r <= -1;
    end
  end

  uart_fifo fifo_tx (
      .wrreq(en_w && addr == 0),
      .wrclk(clk),
      .data(data_w),
      .wrfull(),  // TODO: Halt cpu?

      .rdclk(uart_clk),
      .rdreq(tx_rdreq),
      .q(tx_rd),
      .rdempty(tx_rdempty)
  );

  logic       tx_rdreq = 0;
  logic [7:0] tx_rd;
  logic       tx_rdempty;
  logic [7:0] tx_data;
  logic [4:0] tx_state = 9;
  // 0: start bit
  // 1-8: data bit n
  // 9: stop bit/wait

  always_ff @(negedge uart_clk) begin
    tx_rdreq <= 0;

    case (tx_state)
      0: begin
        // Save data
        tx_data  <= tx_rd;

        // Start bit
        uart_tx  <= 0;
        tx_state <= 1;
      end
      1, 2, 3, 4, 5, 6, 7, 8: begin
        // Data bit
        uart_tx  <= tx_data[0];
        tx_data  <= tx_data >> 1;
        tx_state <= tx_state + 1;
      end
      default: begin
        // Stop bit
        uart_tx <= 1;
        if (!tx_rdempty) begin
          tx_rdreq <= 1;
          tx_state <= 0;
        end
      end
    endcase
  end

  initial begin
    uart_tx = 1;
  end
endmodule
