/*// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

...
...

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
	.out(mac_out)
); 

...
...

endmodule*/

// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
module mac_tile (
  clk,
  out_s,
  in_w,
  out_e,
  in_n,
  inst_w,
  inst_e,
  reset
);

  parameter bw      = 4;
  parameter psum_bw = 16;

  output [psum_bw-1:0] out_s;
  input  [bw-1:0]      in_w;     // inst[1]: execute, inst[0]: kernel loading
  output [bw-1:0]      out_e;
  input  [1:0]         inst_w;
  output [1:0]         inst_e;
  input  [psum_bw-1:0] in_n;
  input                clk;
  input                reset;

  // -----------------------
  // Latches / State
  // -----------------------
  reg  [1:0]           inst_q;        // {exec_q, load_q}
  reg  [bw-1:0]        a_q;           // activation
  reg  [bw-1:0]        b_q;           // weight
  reg  [psum_bw-1:0]   c_q;           // psum
  reg                  load_ready_q;  // kernel-load readiness

  wire [psum_bw-1:0]   mac_out;

  // -----------------------
  // Static connections
  // -----------------------
  assign out_e  = a_q;      // a_q is connected to out_e
  assign inst_e = inst_q;   // inst_e is connected to inst_q
  assign out_s  = mac_out;

  // -----------------------
  // MAC instance
  // -----------------------
  mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a  (a_q),
    .b  (b_q),
    .c  (c_q),
    .out(mac_out)
  );

  // -----------------------
  // Synchronous logic
  // -----------------------
  always @(posedge clk) begin
    if (reset) begin
      // When reset == 1: inst_q -> 0, load_ready_q -> 1
      inst_q        <= 2'b00;
      load_ready_q  <= 1'b1;

      // Safe reset of latches
      a_q           <= {bw{1'b0}};
      b_q           <= {bw{1'b0}};
      c_q           <= {psum_bw{1'b0}};
    end else begin
      // Latch psum input every cycle (synchronous)
      c_q <= in_n;

      // Accept inst_w[1] (execution) always into inst_q[1]
      inst_q[1] <= inst_w[1];

      // When load_ready_q == 0, latch inst_w[0] into inst_q[0]
      // (otherwise keep it 0 until we finish the initial kernel load)
      if (load_ready_q == 1'b0) begin
        inst_q[0] <= inst_w[0];
      end else begin
        inst_q[0] <= 1'b0;
      end

      // When either inst_w[0] or inst_w[1], accept new in_w into a_q
      if (inst_w[0] | inst_w[1]) begin
        a_q <= in_w;
      end

      // When kernel load requested AND ready, capture weight and clear ready
      if (inst_w[0] & load_ready_q) begin
        b_q          <= in_w;
        load_ready_q <= 1'b0;
      end
      // Note: per spec, load_ready_q returns to 1 only on reset.
    end
  end

endmodule
