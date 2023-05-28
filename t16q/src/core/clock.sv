`default_nettype none

typedef struct packed {
  bit ph0;
  bit ph1;
} Clock;

module ClockGen #(
    parameter int DIVIDE = 0
) (
    input clkin,
    output Clock out
);
  logic [DIVIDE:0] counter;

  always_ff @(posedge clkin) counter <= counter + 1;
  assign out.ph0 = counter[DIVIDE];

  // This clock must be assigned asynchronously to delay updating the combinatorial logic
  always_ff @(negedge out.ph0) out.ph1 <= !out.ph1;
endmodule
