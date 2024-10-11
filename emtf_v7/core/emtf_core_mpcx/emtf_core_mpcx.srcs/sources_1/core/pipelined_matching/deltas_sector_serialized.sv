`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2024 07:47:16 AM
// Design Name: 
// Module Name: deltas_sector_serialized
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "vppc_macros.sv"

module deltas_sector_serialized
(
	 vi, hi, ci, si,
	 ph_match,
	 th_match,
     cpat_match,
     ph_q,
     th_window,
     th_window_z0,
     two_st_tight_timing,

     phi,
     theta,
     cpattern,
     delta_ph,
     delta_th,
     sign_ph,
     sign_th,
     rank,
     vir, hir, cir, sir,
     clk
);
`include "spbits.sv"

	//[zone][station 0-3]
	input [seg_ch-1:0] vi [3:0][3:0]; // valid
	input [1:0] 	   hi [3:0][3:0]; // bx index
	input [2:0] 	   ci [3:0][3:0]; // chamber
	input [3:0] 	   si [3:0]; // segment
	input [bw_fph-1:0] ph_match [3:0][3:0]; // matching ph
	input [bw_th-1:0]  th_match   [3:0][3:0][seg_ch-1:0]; // matching th, 2 segments 
	input [3:0] 	   cpat_match [3:0][3:0]; // matching pattern
	// best ranks [zone][num]
	input [bwr-1:0]    ph_q [3:0];
	
	input [bw_th-1:0]  th_window; // max th diff
	input [bw_th-1:0]  th_window_z0; // max th diff for zone 0
	input two_st_tight_timing;

	// precise phi and theta of candidates
	// [zone][pattern_num]
	output [bw_fph-1:0] phi [3:0];
	output [bw_th-1:0] 	theta [3:0];
	// [zone][pattern_num][station]
	output [3:0] 		cpattern [3:0][3:0];
	// ph and th deltas from best stations
	// [zone][pattern_num], last index: 0=12, 1=13, 2=14, 3=23, 4=24, 5=34
	output [bw_fph-1:0] delta_ph [3:0][5:0];
	output [bw_th-1:0] 	delta_th [3:0][5:0]; 
	output [5:0] 		sign_ph[3:0];
	output [5:0] 		sign_th[3:0];
	// updated ranks [zone][pattern_num]
	output [bwr:0] 		rank [3:0];
	//[zone][pattern_num][station 0-3]
	output [seg_ch-1:0] vir [3:0][3:0]; // valid
	output [1:0] 		hir [3:0][3:0]; // bx index
	output [2:0] 		cir [3:0][3:0]; // chamber
	output [3:0] 		sir [3:0]; // segment
	
	input 				clk;


	genvar i, j;
	generate
		for (i = 0; i < 4; i = i+1) // zone loop
		begin: zl11
            deltas_serialized #(.me11(0)) da // all stations now treated equally, per Jia Fu request 2016-10-18
            (
             .vi (vi[i]), 
             .hi (hi[i]), 
             .ci (ci[i]), 
             .si (si[i]),
             .ph_match (ph_match[i]),
             .th_match (th_match[i]),
             .cpat_match (cpat_match[i]),
             .ph_q (ph_q[i]),
             .th_window ((i == 0) ? th_window_z0 : th_window), // use different window for zone 0, per Andrew 2018-4-30
             .two_st_tight_timing (two_st_tight_timing),

             .phi (phi[i]),
             .theta (theta[i]),
             .cpattern (cpattern[i]),
             .delta_ph (delta_ph[i]),
             .delta_th (delta_th[i]),
             .sign_ph (sign_ph[i]),
             .sign_th (sign_th[i]),
             .rank(rank[i]),
             .vir (vir[i]), 
             .hir (hir[i]), 
             .cir (cir[i]), 
             .sir (sir[i]),
             .clk (clk)
             );
		end

	endgenerate

endmodule





