`default_nettype none

typedef struct packed {
  bit ph0;
  bit ph1;
} Clock;

module ClockGen #(
    parameter int DIVIDE = 4
) (
    input clkin,
    output Clock out
);
  logic [DIVIDE:0] counter;

  always_ff @(posedge clkin) counter <= counter + 1;
  assign out.ph0 = counter[DIVIDE-2];
  assign out.ph1 = counter[DIVIDE-1];
endmodule
