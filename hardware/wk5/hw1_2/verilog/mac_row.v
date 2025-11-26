/*// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  output [col-1:0] valid;
  input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;

  wire  [(col+1)*bw-1:0] temp;

  assign temp[bw-1:0]   = in_w;

  genvar i;
  for (i=1; i < col+1 ; i=i+1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
         .clk(clk),
         .reset(reset),
	 .in_w( temp[bw*i-1:bw*(i-1)]),
	 .out_e(temp[bw*(i+1)-1:bw*i]),
	 .inst_w(...),
	 .inst_e(...),
	 .in_n(...),
	 .out_s(...));
  end

endmodule*/

// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset);

  parameter bw      = 4;
  parameter psum_bw = 16;
  parameter col     = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  output [col-1:0]         valid;
  input  [bw-1:0]          in_w;   // inst[1]: execute, inst[0]: kernel loading
  input  [1:0]             inst_w;
  input  [psum_bw*col-1:0] in_n;

  // Weight/activation east-bound pipeline (like provided "temp" use-case)
  wire  [(col+1)*bw-1:0]   temp;
  assign temp[bw-1:0] = in_w;

  // 2-bit instruction east-bound pipeline (mirrors "temp" use-case)
  wire  [2*(col+1)-1:0]    temp_inst;
  assign temp_inst[1:0] = inst_w;

  genvar i;
  generate
    for (i = 1; i < col+1; i = i + 1) begin : col_num
      // Each instance i corresponds to column (i-1)
      mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
        .clk    (clk),
        .reset  (reset),
        .in_w   (temp[bw*i-1       : bw*(i-1)]),
        .out_e  (temp[bw*(i+1)-1   : bw*i]),
        .inst_w (temp_inst[2*i-1   : 2*(i-1)]),
        .inst_e (temp_inst[2*(i+1)-1 : 2*i]),
        .in_n   (in_n[psum_bw*i-1  : psum_bw*(i-1)]),
        .out_s  (out_s[psum_bw*i-1 : psum_bw*(i-1)])
      );

      // valid for column (i-1) is inst_e[1] produced by that column
      // Which sits at the MSB of the 2-bit slice wired to temp_inst[2*(i+1)-1 : 2*i]
      assign valid[i-1] = temp_inst[2*(i+1)-1];
    end
  endgenerate

endmodule
