`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2024 11:01:55 AM
// Design Name: 
// Module Name: best_tracks_pipelined
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

module best_tracks_pipelined(
    new_bx_data_flag,
     phi,
     theta,
     cpattern,
     delta_ph,
     delta_th,
     sign_ph,
     sign_th,
     rank,
	 vi, 
     hi, 
     ci, 
     si,

     bt_phi,
     bt_theta,
     bt_cpattern,
     bt_delta_ph,
     bt_delta_th,
     bt_sign_ph,
     bt_sign_th,
     bt_rank,
	 bt_vi, 
     bt_hi, 
     bt_ci, 
     bt_si,

     clk
);

`include "spbits.sv"

    input new_bx_data_flag;
    
	// precise phi and theta of candidates
	// [zone][pattern_num]
	input [bw_fph-1:0] phi [3:0][2:0];
	input [bw_th-1:0]  theta [3:0][2:0];
	// [zone][pattern_num][station]
	input [3:0] 	   cpattern [3:0][2:0][3:0];
	// ph and th deltas from best stations
	// [zone][pattern_num], last index: 0=12, 1=13, 2=14, 3=23, 4=24, 5=34
	input [bw_fph-1:0] delta_ph [3:0][2:0][5:0];
	input [bw_th-1:0]  delta_th [3:0][2:0][5:0]; 
	input [5:0] 	   sign_ph[3:0][2:0];
	input [5:0] 	   sign_th[3:0][2:0];
	// updated ranks [zone][pattern_num]
	input [bwr:0] 	   rank [3:0][2:0];
	//[zone][pattern_num][station 0-3]
	input [seg_ch-1:0] vi [3:0][2:0][3:0]; // valid
	input [1:0] 	   hi [3:0][2:0][3:0]; // bx index
	input [2:0] 	   ci [3:0][2:0][3:0]; // chamber
	input [3:0] 	   si [3:0][2:0]; // segment
	
	// precise phi and theta of best tracks
	// [best_track_num]
	output wire [bw_fph-1:0] bt_phi [2:0];
	output wire [bw_th-1:0] 	bt_theta [2:0];
	// [best_track_num][station]
	output wire [3:0] 		bt_cpattern [2:0][3:0];
	// ph and th deltas from best stations
	// [best_track_num], last index: 0=12, 1=13, 2=14, 3=23, 4=24, 5=34
	output wire [bw_fph-1:0] bt_delta_ph [2:0][5:0];
	output wire [bw_th-1:0] 	bt_delta_th [2:0][5:0]; 
	output wire [5:0] 		bt_sign_ph[2:0];
	output wire [5:0] 		bt_sign_th[2:0];
	// ranks [best_track_num]
	output wire [bwr:0] 		bt_rank [2:0];
	//[best_track_num][station 0-3]
	output wire [seg_ch-1:0] bt_vi [2:0][4:0]; // valid
	output wire [1:0] 		bt_hi [2:0][4:0]; // bx index
	output wire [3:0] 		bt_ci [2:0][4:0]; // chamber
	output wire [4:0]		bt_si [2:0]; // segment
	
	input clk;



	wire [seg_ch-1:0] cn_vi [3:0][2:0][4:0]; // valid
	wire [1:0] 		cn_hi [3:0][2:0][4:0]; // bx index
	wire [3:0] 		cn_ci [3:0][2:0][4:0]; // chamber
	wire  		    cn_si [3:0][2:0][4:0]; // segment
    
    wire [23:0] exists;
    wire [23:0] larger [24:0];
	    
    // When new_bx_data_flag is high, the inputs on the interface are valid
    best_tracks_stage1 bt_stg1(
        .new_bx_data_flag(new_bx_data_flag),
        .rank(rank),
        .vi(vi), 
        .hi(hi), 
        .ci(ci), 
        .si(si),     
        .cn_vi_o(cn_vi),
        .cn_hi_o(cn_hi),
        .cn_ci_o(cn_ci),
        .cn_si_o(cn_si),
        .exists_o(exists),
        .larger_o(larger),
        .clk(clk)
    );
    
    
    // Info to delay 1bx for 2nd stage
    reg stg2_new_bx_data_flag;
	reg [bw_fph-1:0] stg2_phi [3:0][2:0];   // [zone][pattern_num]
	reg [bw_th-1:0]  stg2_theta [3:0][2:0];
	reg [3:0] 	     stg2_cpattern [3:0][2:0][3:0]; // [zone][pattern_num][station]
	reg [bw_fph-1:0] stg2_delta_ph [3:0][2:0][5:0];
	reg [bw_th-1:0]  stg2_delta_th [3:0][2:0][5:0]; 
	reg [5:0] 	     stg2_sign_ph[3:0][2:0];
	reg [5:0] 	     stg2_sign_th[3:0][2:0];
	reg [bwr:0] 	 stg2_rank [3:0][2:0];
	
    
    best_tracks_stage2 bt_stg2(
        .new_bx_data_flag(stg2_new_bx_data_flag),
        .phi(stg2_phi),
        .theta(stg2_theta),
        .cpattern(stg2_cpattern),
        .delta_ph(stg2_delta_ph),
        .delta_th(stg2_delta_th),
        .sign_ph(stg2_sign_ph),
        .sign_th(stg2_sign_th),
        .rank(stg2_rank),
        .cn_vi(cn_vi), 
        .cn_hi(cn_hi), 
        .cn_ci(cn_ci), 
        .cn_si(cn_si),
        .exists_i(exists),
        .larger_i(larger),
        .bt_phi(bt_phi),
        .bt_theta(bt_theta),
        .bt_cpattern(bt_cpattern),
        .bt_delta_ph(bt_delta_ph),
        .bt_delta_th(bt_delta_th),
        .bt_sign_ph(bt_sign_ph),
        .bt_sign_th(bt_sign_th),
        .bt_rank(bt_rank),
        .bt_vi(bt_vi), 
        .bt_hi(bt_hi), 
        .bt_ci(bt_ci), 
        .bt_si(bt_si),
        .clk(clk)
    );

	
	always @(posedge clk)
	begin
	   stg2_new_bx_data_flag <= new_bx_data_flag; // stg2 delayed by 1 clock
       stg2_phi     <= 	phi; 	  
       stg2_theta   <=  theta;  
       stg2_cpattern<=  cpattern; 
       stg2_delta_ph<=  delta_ph; 
       stg2_delta_th<=  delta_th; 
       stg2_sign_ph <= 	sign_ph;
       stg2_sign_th <= 	sign_th;
       stg2_rank    <=  rank; 
	end

endmodule
