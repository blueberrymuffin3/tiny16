`default_nettype none

typedef struct packed {
  bit ph0;
  bit ph1;
} Clock;

module ClockGen (
    input clkin,
    output Clock out
);
  assign out.ph0 = clkin;

  // This clock must be assigned asynchronously to delay updating the combinatorial logic
  always_ff @(negedge out.ph0) out.ph1 <= !out.ph1;
endmodule
