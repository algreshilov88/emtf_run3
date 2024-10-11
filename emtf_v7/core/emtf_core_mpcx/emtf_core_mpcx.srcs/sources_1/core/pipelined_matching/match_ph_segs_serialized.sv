`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2024 01:49:30 PM
// Design Name: 
// Module Name: match_ph_segs_serialized
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

module match_ph_segs_serialized(

     ph_num, ph_q,
     ph, vl,
	 th11, th, cpat,

	 vi, hi, ci, si,
	 ph_match,
	 th_match,
	 cpat_match,
	 ph_qr,
     clk120
);

`include "spbits.sv"

    // numbers of best ranks [zone][rank number]
    input [bpow:0] 	ph_num [3:0]; 

    // best ranks [zone][rank number]
    input [5:0] 	ph_q [3:0]; 

    // ph outputs delayed and extended [bx_history][station][chamber][segment]
    // most recent in bx = 0
    input [bw_fph-1:0] 	ph   [max_drift-1:0][5:0][8:0][seg_ch-1:0];
	// valid flags
    input [seg_ch-1:0] 	vl   [max_drift-1:0][5:0][8:0];
	// thetas
    input [bw_th-1:0] 	th11 [max_drift-1:0][2:0][2:0][th_ch11-1:0];
    input [bw_th-1:0] 	th   [max_drift-1:0][5:0][8:0][seg_ch-1:0];
    input [3:0] 		cpat [max_drift-1:0][5:0][8:0][seg_ch-1:0];
    
	// find_segment outputs, in terms of segments match in zones [zone][station 0-3]
	output [seg_ch-1:0] vi [3:0][3:0]; // valid (for each segment in chamber, so we can identify which th to use later)
	output [1:0] 		hi [3:0][3:0]; // bx index
	output [2:0] 		ci [3:0][3:0]; // chamber
	output [3:0] 		si [3:0]; // segment which has matching ph
	output [bw_fph-1:0] ph_match [3:0][3:0]; // matching phi
	// suspected matching th coordinates, all taken from chambers where ph comes from
	// [zone][pattern_num][station 0-3][segment]
	output [bw_th-1:0]	th_match   [3:0][3:0][seg_ch-1:0]; // matching th, 2 segments 
	output [3:0] 		cpat_match [3:0][3:0]; // matching patterns
    // best ranks [zone][rank number]
    output reg [5:0] 	ph_qr [3:0]; 

    input 				clk120;
    
    reg [5:0] 	ph_q_hold1 [3:0];
    reg [5:0] 	ph_q_hold2 [3:0];

	// segments rerouted for find_segment inputs
	// see find_segment_reroute.xlsx for details
	// indexes are: [bx_history][chamber][segment]
	reg [bw_fph-1:0] ph_seg___z0_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z0_s0 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z0_s1 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z0_s1 [max_drift-1:0][3:0];
	reg [bw_fph-1:0] ph_seg___z0_s2 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z0_s2 [max_drift-1:0][3:0];
	reg [bw_fph-1:0] ph_seg___z0_s3 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z0_s3 [max_drift-1:0][3:0];
	
	reg [bw_fph-1:0] ph_seg___z1_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z1_s0 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z1_s1 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z1_s1 [max_drift-1:0][3:0];
	reg [bw_fph-1:0] ph_seg___z1_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z1_s2 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z1_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z1_s3 [max_drift-1:0][6:0];
	
	reg [bw_fph-1:0] ph_seg___z2_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z2_s0 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z2_s1 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z2_s1 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z2_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z2_s2 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z2_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z2_s3 [max_drift-1:0][6:0];
	
	reg [bw_fph-1:0] ph_seg___z3_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z3_s0 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z3_s1 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z3_s1 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z3_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z3_s2 [max_drift-1:0][6:0];
	reg [bw_fph-1:0] ph_seg___z3_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [seg_ch-1:0] ph_seg_v_z3_s3 [max_drift-1:0][6:0];

	
	reg [bw_th-1:0] th_seg___z0_s0 [max_drift-1:0][6:0][th_ch11-1:0];
	reg [bw_th-1:0] th_seg___z0_s1 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z0_s2 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z0_s3 [max_drift-1:0][3:0][seg_ch-1:0];
	
	reg [bw_th-1:0] th_seg___z1_s0 [max_drift-1:0][6:0][th_ch11-1:0];
	reg [bw_th-1:0] th_seg___z1_s1 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z1_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z1_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	
	reg [bw_th-1:0] th_seg___z2_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z2_s1 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z2_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z2_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	
	reg [bw_th-1:0] th_seg___z3_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z3_s1 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z3_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [bw_th-1:0] th_seg___z3_s3 [max_drift-1:0][6:0][seg_ch-1:0];

	reg [3:0] cpat_seg___z0_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z0_s1 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z0_s2 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z0_s3 [max_drift-1:0][3:0][seg_ch-1:0];
	
	reg [3:0] cpat_seg___z1_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z1_s1 [max_drift-1:0][3:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z1_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z1_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	
	reg [3:0] cpat_seg___z2_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z2_s1 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z2_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z2_s3 [max_drift-1:0][6:0][seg_ch-1:0];
	
	reg [3:0] cpat_seg___z3_s0 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z3_s1 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z3_s2 [max_drift-1:0][6:0][seg_ch-1:0];
	reg [3:0] cpat_seg___z3_s3 [max_drift-1:0][6:0][seg_ch-1:0];

	`int i, j, k;
	always @(*)
	begin
		// segments rerouted for find_segment inputs
		// see find_segment_reroute.xlsx for details
		// indexes are: [bx_history][chamber][segment]
		// excel file line shown at the end of each code line
		for (i = 0; i < max_drift; i = i+1) // bx_history loop
		begin
			for (j = 0; j < 7; j = j+1) // chamber loop for 7-chamber finders
			begin
			    // j = 0 is neighbor sector chamber
                // j = 1,2,3 are subsector 1 chambers
                // j = 4,5,6 are subsector 2 chambers
				for (k = 0; k < th_ch11; k = k+1) // segment loop for ME11 only
				begin
					th_seg___z0_s0[i][j][k] = (j == 0) ? th11[i][2][0][k] : (j < 4) ? th11[i][0][j-1][k] : th11[i][1][j-4][k]; // 2
					th_seg___z1_s0[i][j][k] = (j == 0) ? th11[i][2][0][k] : (j < 4) ? th11[i][0][j-1][k] : th11[i][1][j-4][k]; // 7
				end
				
				for (k = 0; k < seg_ch; k = k+1) // segment loop all other chambers
				begin
					ph_seg___z0_s0[i][j][k] = (j == 0) ? ph[i][5][0][k] : (j < 4) ? ph[i][0][j-1][k] : ph[i][1][j-4][k]; // 2
					ph_seg_v_z0_s0[i][j][k] = (j == 0) ? vl[i][5][0][k] : (j < 4) ? vl[i][0][j-1][k] : vl[i][1][j-4][k]; 

					ph_seg___z1_s0[i][j][k] = (j == 0) ? ph[i][5][0][k] : (j < 4) ?	ph[i][0][j-1][k] : ph[i][1][j-4][k]; // 7
					ph_seg_v_z1_s0[i][j][k] = (j == 0) ? vl[i][5][0][k] : (j < 4) ?	vl[i][0][j-1][k] : vl[i][1][j-4][k];
					ph_seg___z1_s2[i][j][k] = (j == 0) ? ph[i][5][6][k] : ph[i][3][j+2][k]; // 9
					ph_seg_v_z1_s2[i][j][k] = (j == 0) ? vl[i][5][6][k] : vl[i][3][j+2][k];
					ph_seg___z1_s3[i][j][k] = (j == 0) ? ph[i][5][8][k] : ph[i][4][j+2][k]; // 10
					ph_seg_v_z1_s3[i][j][k] = (j == 0) ? vl[i][5][8][k] : vl[i][4][j+2][k];

					ph_seg___z2_s0[i][j][k] = (j == 0) ? ph[i][5][1][k] : (j < 4) ? ph[i][0][j+2][k] : ph[i][1][j-1][k]; // 12
					ph_seg_v_z2_s0[i][j][k] = (j == 0) ? vl[i][5][1][k] : (j < 4) ? vl[i][0][j+2][k] : vl[i][1][j-1][k];
					ph_seg___z2_s1[i][j][k] = (j == 0) ? ph[i][5][4][k] : ph[i][2][j+2][k]; // 13
					ph_seg_v_z2_s1[i][j][k] = (j == 0) ? vl[i][5][4][k] : vl[i][2][j+2][k]; 
					ph_seg___z2_s2[i][j][k] = (j == 0) ? ph[i][5][6][k] : ph[i][3][j+2][k]; // 14
					ph_seg_v_z2_s2[i][j][k] = (j == 0) ? vl[i][5][6][k] : vl[i][3][j+2][k];
					ph_seg___z2_s3[i][j][k] = (j == 0) ? ph[i][5][8][k] : ph[i][4][j+2][k]; // 15 
					ph_seg_v_z2_s3[i][j][k] = (j == 0) ? vl[i][5][8][k] : vl[i][4][j+2][k];

					ph_seg___z3_s0[i][j][k] = (j == 0) ? ph[i][5][2][k] : (j < 4) ? ph[i][0][j+5][k] : ph[i][1][j+2][k]; // 18
					ph_seg_v_z3_s0[i][j][k] = (j == 0) ? vl[i][5][2][k] : (j < 4) ? vl[i][0][j+5][k] : vl[i][1][j+2][k];	   
					ph_seg___z3_s1[i][j][k] = (j == 0) ? ph[i][5][4][k] : ph[i][2][j+2][k]; // 19							   
					ph_seg_v_z3_s1[i][j][k] = (j == 0) ? vl[i][5][4][k] : vl[i][2][j+2][k];									   
					ph_seg___z3_s2[i][j][k] = (j == 0) ? ph[i][5][6][k] : ph[i][3][j+2][k]; // 20							   
					ph_seg_v_z3_s2[i][j][k] = (j == 0) ? vl[i][5][6][k] : vl[i][3][j+2][k];                                    
				    ph_seg___z3_s3[i][j][k] = 0; // no station 4 in zone 3
				    ph_seg_v_z3_s3[i][j][k] = 0; // no station 4 in zone 3

					cpat_seg___z0_s0[i][j][k] = (j == 0) ? cpat[i][5][0][k] : (j < 4) ? cpat[i][0][j-1][k] : cpat[i][1][j-4][k]; // 2

					cpat_seg___z1_s0[i][j][k] = (j == 0) ? cpat[i][5][0][k] : (j < 4) ? cpat[i][0][j-1][k] : cpat[i][1][j-4][k]; // 7
					cpat_seg___z1_s2[i][j][k] = (j == 0) ? cpat[i][5][6][k] : cpat[i][3][j+2][k]; // 9
					cpat_seg___z1_s3[i][j][k] = (j == 0) ? cpat[i][5][8][k] : cpat[i][4][j+2][k]; // 10

					cpat_seg___z2_s0[i][j][k] = (j == 0) ? cpat[i][5][1][k] : (j < 4) ? cpat[i][0][j+2][k] : cpat[i][1][j-1][k]; // 12
					cpat_seg___z2_s1[i][j][k] = (j == 0) ? cpat[i][5][4][k] : cpat[i][2][j+2][k]; // 13
					cpat_seg___z2_s2[i][j][k] = (j == 0) ? cpat[i][5][6][k] : cpat[i][3][j+2][k]; // 14
					cpat_seg___z2_s3[i][j][k] = (j == 0) ? cpat[i][5][8][k] : cpat[i][4][j+2][k]; // 15 

					cpat_seg___z3_s0[i][j][k] = (j == 0) ? cpat[i][5][2][k] : (j < 4) ? cpat[i][0][j+5][k] : cpat[i][1][j+2][k]; // 18
					cpat_seg___z3_s1[i][j][k] = (j == 0) ? cpat[i][5][4][k] : cpat[i][2][j+2][k]; // 19
					cpat_seg___z3_s2[i][j][k] = (j == 0) ? cpat[i][5][6][k] : cpat[i][3][j+2][k]; // 20
				    cpat_seg___z3_s3[i][j][k] = 0; // no station 4 in zone 3
					
					th_seg___z1_s2[i][j][k] = (j == 0) ? th[i][5][6][k] : th[i][3][j+2][k]; // 9
					th_seg___z1_s3[i][j][k] = (j == 0) ? th[i][5][8][k] : th[i][4][j+2][k]; // 10

					th_seg___z2_s0[i][j][k] = (j == 0) ? th[i][5][1][k] : (j < 4) ?	 th[i][0][j+2][k] : th[i][1][j-1][k]; // 12
					th_seg___z2_s1[i][j][k] = (j == 0) ? th[i][5][4][k] : th[i][2][j+2][k]; // 13
					th_seg___z2_s2[i][j][k] = (j == 0) ? th[i][5][6][k] : th[i][3][j+2][k]; // 14
					th_seg___z2_s3[i][j][k] = (j == 0) ? th[i][5][8][k] : th[i][4][j+2][k]; // 15 

					th_seg___z3_s0[i][j][k] = (j == 0) ? th[i][5][2][k] : (j < 4) ?	 th[i][0][j+5][k] : th[i][1][j+2][k]; // 18
					th_seg___z3_s1[i][j][k] = (j == 0) ? th[i][5][4][k] : th[i][2][j+2][k]; // 19
					th_seg___z3_s2[i][j][k] = (j == 0) ? th[i][5][6][k] : th[i][3][j+2][k]; // 20
				    th_seg___z3_s3[i][j][k] = 0; // no station 4 in zone 3
				    

				end
			end
			for (j = 0; j < 4; j = j+1) // chamber loop for 4-chamber finders
			begin
			    // j = 0 is neighbor sector chamber
                // j = 1,2,3 are native sector chambers
				for (k = 0; k < seg_ch; k = k+1) // segment loop
				begin
					ph_seg___z0_s1[i][j][k] = (j == 0) ? ph[i][5][3][k] : ph[i][2][j-1][k]; // 3
					ph_seg_v_z0_s1[i][j][k] = (j == 0) ? vl[i][5][3][k] : vl[i][2][j-1][k]; 
					ph_seg___z0_s2[i][j][k] = (j == 0) ? ph[i][5][5][k] : ph[i][3][j-1][k]; // 4
					ph_seg_v_z0_s2[i][j][k] = (j == 0) ? vl[i][5][5][k] : vl[i][3][j-1][k];
					ph_seg___z0_s3[i][j][k] = (j == 0) ? ph[i][5][7][k] : ph[i][4][j-1][k]; // 5
					ph_seg_v_z0_s3[i][j][k] = (j == 0) ? vl[i][5][7][k] : vl[i][4][j-1][k];

					ph_seg___z1_s1[i][j][k] = (j == 0) ? ph[i][5][3][k] : ph[i][2][j-1][k]; // 8
					ph_seg_v_z1_s1[i][j][k] = (j == 0) ? vl[i][5][3][k] : vl[i][2][j-1][k];

					cpat_seg___z0_s1[i][j][k] = (j == 0) ? cpat[i][5][3][k] : cpat[i][2][j-1][k]; // 3
					cpat_seg___z0_s2[i][j][k] = (j == 0) ? cpat[i][5][5][k] : cpat[i][3][j-1][k]; // 4
					cpat_seg___z0_s3[i][j][k] = (j == 0) ? cpat[i][5][7][k] : cpat[i][4][j-1][k]; // 5

					cpat_seg___z1_s1[i][j][k] = (j == 0) ? cpat[i][5][3][k] : cpat[i][2][j-1][k]; // 8


					th_seg___z0_s1[i][j][k] = (j == 0) ? th[i][5][3][k] : th[i][2][j-1][k]; // 3
					th_seg___z0_s2[i][j][k] = (j == 0) ? th[i][5][5][k] : th[i][3][j-1][k]; // 4
					th_seg___z0_s3[i][j][k] = (j == 0) ? th[i][5][7][k] : th[i][4][j-1][k]; // 5

					th_seg___z1_s1[i][j][k] = (j == 0) ? th[i][5][3][k] : th[i][2][j-1][k]; // 8
				end
			end
		end // for (i = 0; i < max_drift; i = i+1)
	end
	
	
	
	always @(posedge clk120)
	begin 
	   ph_q_hold1 <= ph_q;
	   ph_q_hold2 <= ph_q_hold1;
	   ph_qr <= ph_q_hold2; // just propagate ranks to outputs
	end
	
	
	
     // name = fs_zone_station
    find_segment_serialized #(.zone_cham (7), .zone_seg (th_ch11), .station (1)) fs_00(.ph_pat_p (ph_num[0]), .ph_pat_q_p (ph_q[0]), .ph_seg_p(ph_seg___z0_s0), .ph_seg_v_p(ph_seg_v_z0_s0), .th_seg_p(th_seg___z0_s0), .cpat_seg_p(cpat_seg___z0_s0), .vid(vi[0][0]), .hid(hi[0][0]), .cid(ci[0][0]), .sid(si[0][0]), .ph_match(ph_match[0][0]), .th_match(th_match[0][0]), .cpat_match(cpat_match[0][0]), .clk(clk120));
    find_segment_serialized #(.zone_cham (4), .zone_seg (seg_ch),  .station (2)) fs_01(.ph_pat_p (ph_num[0]), .ph_pat_q_p (ph_q[0]), .ph_seg_p(ph_seg___z0_s1), .ph_seg_v_p(ph_seg_v_z0_s1), .th_seg_p(th_seg___z0_s1), .cpat_seg_p(cpat_seg___z0_s1), .vid(vi[0][1]), .hid(hi[0][1]), .cid(ci[0][1]), .sid(si[0][1]), .ph_match(ph_match[0][1]), .th_match(th_match[0][1]), .cpat_match(cpat_match[0][1]), .clk(clk120));
    find_segment_serialized #(.zone_cham (4), .zone_seg (seg_ch),  .station (3)) fs_02(.ph_pat_p (ph_num[0]), .ph_pat_q_p (ph_q[0]), .ph_seg_p(ph_seg___z0_s2), .ph_seg_v_p(ph_seg_v_z0_s2), .th_seg_p(th_seg___z0_s2), .cpat_seg_p(cpat_seg___z0_s2), .vid(vi[0][2]), .hid(hi[0][2]), .cid(ci[0][2]), .sid(si[0][2]), .ph_match(ph_match[0][2]), .th_match(th_match[0][2]), .cpat_match(cpat_match[0][2]), .clk(clk120));
    find_segment_serialized #(.zone_cham (4), .zone_seg (seg_ch),  .station (4)) fs_03(.ph_pat_p (ph_num[0]), .ph_pat_q_p (ph_q[0]), .ph_seg_p(ph_seg___z0_s3), .ph_seg_v_p(ph_seg_v_z0_s3), .th_seg_p(th_seg___z0_s3), .cpat_seg_p(cpat_seg___z0_s3), .vid(vi[0][3]), .hid(hi[0][3]), .cid(ci[0][3]), .sid(si[0][3]), .ph_match(ph_match[0][3]), .th_match(th_match[0][3]), .cpat_match(cpat_match[0][3]), .clk(clk120));
                                                                                                                                                                                                                                                                                                                                                                                                                                
    find_segment_serialized #(.zone_cham (7), .zone_seg (th_ch11), .station (1)) fs_10(.ph_pat_p (ph_num[1]), .ph_pat_q_p (ph_q[1]), .ph_seg_p(ph_seg___z1_s0), .ph_seg_v_p(ph_seg_v_z1_s0), .th_seg_p(th_seg___z1_s0), .cpat_seg_p(cpat_seg___z1_s0), .vid(vi[1][0]), .hid(hi[1][0]), .cid(ci[1][0]), .sid(si[1][0]), .ph_match(ph_match[1][0]), .th_match(th_match[1][0]), .cpat_match(cpat_match[1][0]), .clk(clk120));
    find_segment_serialized #(.zone_cham (4), .zone_seg (seg_ch),  .station (2)) fs_11(.ph_pat_p (ph_num[1]), .ph_pat_q_p (ph_q[1]), .ph_seg_p(ph_seg___z1_s1), .ph_seg_v_p(ph_seg_v_z1_s1), .th_seg_p(th_seg___z1_s1), .cpat_seg_p(cpat_seg___z1_s1), .vid(vi[1][1]), .hid(hi[1][1]), .cid(ci[1][1]), .sid(si[1][1]), .ph_match(ph_match[1][1]), .th_match(th_match[1][1]), .cpat_match(cpat_match[1][1]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (3)) fs_12(.ph_pat_p (ph_num[1]), .ph_pat_q_p (ph_q[1]), .ph_seg_p(ph_seg___z1_s2), .ph_seg_v_p(ph_seg_v_z1_s2), .th_seg_p(th_seg___z1_s2), .cpat_seg_p(cpat_seg___z1_s2), .vid(vi[1][2]), .hid(hi[1][2]), .cid(ci[1][2]), .sid(si[1][2]), .ph_match(ph_match[1][2]), .th_match(th_match[1][2]), .cpat_match(cpat_match[1][2]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (4)) fs_13(.ph_pat_p (ph_num[1]), .ph_pat_q_p (ph_q[1]), .ph_seg_p(ph_seg___z1_s3), .ph_seg_v_p(ph_seg_v_z1_s3), .th_seg_p(th_seg___z1_s3), .cpat_seg_p(cpat_seg___z1_s3), .vid(vi[1][3]), .hid(hi[1][3]), .cid(ci[1][3]), .sid(si[1][3]), .ph_match(ph_match[1][3]), .th_match(th_match[1][3]), .cpat_match(cpat_match[1][3]), .clk(clk120));
                                                                                                                                                                                                                                                                                                                                                                                                                                
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (1)) fs_20(.ph_pat_p (ph_num[2]), .ph_pat_q_p (ph_q[2]), .ph_seg_p(ph_seg___z2_s0), .ph_seg_v_p(ph_seg_v_z2_s0), .th_seg_p(th_seg___z2_s0), .cpat_seg_p(cpat_seg___z2_s0), .vid(vi[2][0]), .hid(hi[2][0]), .cid(ci[2][0]), .sid(si[2][0]), .ph_match(ph_match[2][0]), .th_match(th_match[2][0]), .cpat_match(cpat_match[2][0]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (2)) fs_21(.ph_pat_p (ph_num[2]), .ph_pat_q_p (ph_q[2]), .ph_seg_p(ph_seg___z2_s1), .ph_seg_v_p(ph_seg_v_z2_s1), .th_seg_p(th_seg___z2_s1), .cpat_seg_p(cpat_seg___z2_s1), .vid(vi[2][1]), .hid(hi[2][1]), .cid(ci[2][1]), .sid(si[2][1]), .ph_match(ph_match[2][1]), .th_match(th_match[2][1]), .cpat_match(cpat_match[2][1]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (3)) fs_22(.ph_pat_p (ph_num[2]), .ph_pat_q_p (ph_q[2]), .ph_seg_p(ph_seg___z2_s2), .ph_seg_v_p(ph_seg_v_z2_s2), .th_seg_p(th_seg___z2_s2), .cpat_seg_p(cpat_seg___z2_s2), .vid(vi[2][2]), .hid(hi[2][2]), .cid(ci[2][2]), .sid(si[2][2]), .ph_match(ph_match[2][2]), .th_match(th_match[2][2]), .cpat_match(cpat_match[2][2]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (4)) fs_23(.ph_pat_p (ph_num[2]), .ph_pat_q_p (ph_q[2]), .ph_seg_p(ph_seg___z2_s3), .ph_seg_v_p(ph_seg_v_z2_s3), .th_seg_p(th_seg___z2_s3), .cpat_seg_p(cpat_seg___z2_s3), .vid(vi[2][3]), .hid(hi[2][3]), .cid(ci[2][3]), .sid(si[2][3]), .ph_match(ph_match[2][3]), .th_match(th_match[2][3]), .cpat_match(cpat_match[2][3]), .clk(clk120));
                                                                                                                                                                                                                                                                                                                                                                                                                                
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (1)) fs_30(.ph_pat_p (ph_num[3]), .ph_pat_q_p (ph_q[3]), .ph_seg_p(ph_seg___z3_s0), .ph_seg_v_p(ph_seg_v_z3_s0), .th_seg_p(th_seg___z3_s0), .cpat_seg_p(cpat_seg___z3_s0), .vid(vi[3][0]), .hid(hi[3][0]), .cid(ci[3][0]), .sid(si[3][0]), .ph_match(ph_match[3][0]), .th_match(th_match[3][0]), .cpat_match(cpat_match[3][0]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (2)) fs_31(.ph_pat_p (ph_num[3]), .ph_pat_q_p (ph_q[3]), .ph_seg_p(ph_seg___z3_s1), .ph_seg_v_p(ph_seg_v_z3_s1), .th_seg_p(th_seg___z3_s1), .cpat_seg_p(cpat_seg___z3_s1), .vid(vi[3][1]), .hid(hi[3][1]), .cid(ci[3][1]), .sid(si[3][1]), .ph_match(ph_match[3][1]), .th_match(th_match[3][1]), .cpat_match(cpat_match[3][1]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (3)) fs_32(.ph_pat_p (ph_num[3]), .ph_pat_q_p (ph_q[3]), .ph_seg_p(ph_seg___z3_s2), .ph_seg_v_p(ph_seg_v_z3_s2), .th_seg_p(th_seg___z3_s2), .cpat_seg_p(cpat_seg___z3_s2), .vid(vi[3][2]), .hid(hi[3][2]), .cid(ci[3][2]), .sid(si[3][2]), .ph_match(ph_match[3][2]), .th_match(th_match[3][2]), .cpat_match(cpat_match[3][2]), .clk(clk120));
    find_segment_serialized #(.zone_cham (7), .zone_seg (seg_ch),  .station (4)) fs_33(.ph_pat_p (ph_num[3]), .ph_pat_q_p (ph_q[3]), .ph_seg_p(ph_seg___z3_s3), .ph_seg_v_p(ph_seg_v_z3_s3), .th_seg_p(th_seg___z3_s3), .cpat_seg_p(cpat_seg___z3_s3), .vid(vi[3][3]), .hid(hi[3][3]), .cid(ci[3][3]), .sid(si[3][3]), .ph_match(ph_match[3][3]), .th_match(th_match[3][3]), .cpat_match(cpat_match[3][3]), .clk(clk120));

	
endmodule