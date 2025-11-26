/*// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;

  for (i=1; i < row+1 ; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
      );
  end

  always @ (posedge clk) begin

  end



endmodule*/

// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw      = 4;
  parameter psum_bw = 16;
  parameter col     = 8;
  parameter row     = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0]      in_w;   // inst[1]: execute, inst[0]: kernel loading
  input  [1:0]             inst_w;
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0]         valid;

  // Chain psums vertically through rows:
  // temp_ps[0]   = in_n (top input)
  // temp_ps[i]   = out_s of row i (1..row), which becomes in_n of row i+1
  // final out_s  = temp_ps[row]
  wire [psum_bw*col*(row+1)-1:0] temp_ps;
  assign temp_ps[psum_bw*col-1:0] = in_n;

  // Collect valid vectors from each row; only the last is exported
  wire [col*row-1:0] valid_bus;

  genvar i;
  generate
    for (i = 1; i < row+1; i = i + 1) begin : row_num
      // Local wire to capture valid from this row
      wire [col-1:0] valid_w;

      mac_row #(.bw(bw), .psum_bw(psum_bw), .col(col)) mac_row_instance (
        .clk   (clk),
        .reset (reset),
        .in_w  (in_w[bw*i-1         : bw*(i-1)]),              // west input per row
        .inst_w(inst_w),                                       // propagated within row
        .in_n  (temp_ps[psum_bw*col*i-1 : psum_bw*col*(i-1)]), // psum in from above
        .out_s (temp_ps[psum_bw*col*(i+1)-1 : psum_bw*col*i]), // psum out to below
        .valid (valid_w)
      );

      // Capture per-row valid in a flat bus
      assign valid_bus[col*i-1 : col*(i-1)] = valid_w;
    end
  endgenerate

  // Output psums from the last row
  assign out_s = temp_ps[psum_bw*col*(row+1)-1 : psum_bw*col*row];

  // Only the last row’s valid is used
  assign valid = valid_bus[col*row-1 : col*(row-1)];

  always @ (posedge clk) begin
    // No additional sequential logic required here per current spec
  end

endmodule

