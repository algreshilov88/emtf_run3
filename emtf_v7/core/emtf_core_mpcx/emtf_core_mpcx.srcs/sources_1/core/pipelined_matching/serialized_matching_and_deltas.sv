`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2024 07:17:23 AM
// Design Name: 
// Module Name: serialized_matching_and_deltas
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

module serialized_matching_and_deltas(
    // Ph Matching inputs
    ph_num, ph_q,
    ph, vl,
    th11, th, cpat,
    
    
    // Config Inputs
    th_window,
    th_window_z0,
    two_st_tight_timing,
     
     
    // Deltas Outputs
    phi,
    theta,
    cpattern,
    delta_ph,
    delta_th,
    sign_ph,
    sign_th,
    rank,
    vir, hir, cir, sir,
    
    // Best Track Outputs
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
    
    // Clocks
    clk40, clk120
);
    `include "spbits.sv"
    
    

    input [bpow:0] 	ph_num [3:0][2:0]; // numbers of best ranks [zone][rank number]    
    input [5:0] 	ph_q [3:0][2:0]; // best ranks [zone][rank number]

    // Outputs delayed and extended [bx_history][station][chamber][segment]    -    most recent in bx = 0
    input [bw_fph-1:0] 	ph   [max_drift-1:0][5:0][8:0][seg_ch-1:0];
    input [seg_ch-1:0] 	vl   [max_drift-1:0][5:0][8:0];
    input [bw_th-1:0] 	th11 [max_drift-1:0][2:0][2:0][th_ch11-1:0];
    input [bw_th-1:0] 	th   [max_drift-1:0][5:0][8:0][seg_ch-1:0];
    input [3:0] 		cpat [max_drift-1:0][5:0][8:0][seg_ch-1:0];
    
    input 				clk40;
    input               clk120;
    
    // Configs
	input [bw_th-1:0]  th_window; // max th diff
	input [bw_th-1:0]  th_window_z0; // max th diff for zone 0
	input two_st_tight_timing;

	// precise phi and theta of candidates
	// [zone][pattern_num]
	output reg [bw_fph-1:0] phi [3:0][2:0];
	output reg [bw_th-1:0] 	theta [3:0][2:0];
	// [zone][pattern_num][station]
	output reg [3:0] 		cpattern [3:0][2:0][3:0];
	// ph and th deltas from best stations
	// [zone][pattern_num], last index: 0=12, 1=13, 2=14, 3=23, 4=24, 5=34
	output reg [bw_fph-1:0] delta_ph [3:0][2:0][5:0];
	output reg [bw_th-1:0] 	delta_th [3:0][2:0][5:0]; 
	output reg [5:0] 		sign_ph[3:0][2:0];
	output reg [5:0] 		sign_th[3:0][2:0];
	// updated ranks [zone][pattern_num]
	output reg [bwr:0] 		rank [3:0][2:0];
	//[zone][pattern_num][station 0-3]
	output reg [seg_ch-1:0] vir [3:0][2:0][3:0]; // valid
	output reg [1:0] 		hir [3:0][2:0][3:0]; // bx index
	output reg [2:0] 		cir [3:0][2:0][3:0]; // chamber
	output reg [3:0] 		sir [3:0][2:0]; // segment
	
	// precise phi and theta of best tracks
	// [best_track_num]
	output reg [bw_fph-1:0] bt_phi [2:0];
	output reg [bw_th-1:0] 	bt_theta [2:0];
	// [best_track_num][station]
	output reg [3:0] 		bt_cpattern [2:0][3:0];
	// ph and th deltas from best stations
	// [best_track_num], last index: 0=12, 1=13, 2=14, 3=23, 4=24, 5=34
	output reg [bw_fph-1:0] bt_delta_ph [2:0][5:0];
	output reg [bw_th-1:0] 	bt_delta_th [2:0][5:0]; 
	output reg [5:0] 		bt_sign_ph[2:0];
	output reg [5:0] 		bt_sign_th[2:0];
	// ranks [best_track_num]
	output reg [bwr:0] 		bt_rank [2:0];
	//[best_track_num][station 0-3]
	output reg [seg_ch-1:0] bt_vi [2:0][4:0]; // valid
	output reg [1:0] 		bt_hi [2:0][4:0]; // bx index
	output reg [3:0] 		bt_ci [2:0][4:0]; // chamber
	output reg [4:0]		bt_si [2:0]; // segment
	
	


	// find_segment outputs, in terms of segments match in zones [zone][pattern_num][station 0-3]
	wire [seg_ch-1:0] vi [3:0][3:0]; // valid (for each segment in chamber, so we can identify which th to use later)
	wire [1:0] 		hi [3:0][3:0]; // bx index
	wire [2:0] 		ci [3:0][3:0]; // chamber
	wire [3:0] 		si [3:0]; // segment which has matching ph
	wire [bw_fph-1:0] ph_match [3:0][3:0]; // matching phi
	// suspected matching th coordinates, all taken from chambers where ph comes from
	// [zone][pattern_num][station 0-3][segment]
	wire [bw_th-1:0]	th_match   [3:0][3:0][seg_ch-1:0]; // matching th, 2 segments 
	wire [3:0] 		cpat_match [3:0][3:0]; // matching patterns
    // best ranks [zone][rank number]
    wire [5:0] 	ph_qr [3:0]; 
    
    
    // Deltas Outputs
	wire [bw_fph-1:0]   w_phi [3:0];
	wire [bw_th-1:0] 	w_theta [3:0];
	wire [3:0] 		    w_cpattern [3:0][3:0];
	wire [bw_fph-1:0]   w_delta_ph [3:0][5:0];
	wire [bw_th-1:0] 	w_delta_th [3:0][5:0]; 
	wire [5:0] 		    w_sign_ph[3:0];
	wire [5:0] 		    w_sign_th[3:0];
	wire [bwr:0] 		w_rank [3:0]; // updated ranks [zone]
	wire [seg_ch-1:0] w_vir [3:0][3:0]; // valid
	wire [1:0] 		w_hir [3:0][3:0]; // bx index
	wire [2:0] 		w_cir [3:0][3:0]; // chamber
	wire [3:0] 		w_sir [3:0]; // segment
	
	
    // Deltas outputs fifo
	reg [bw_fph-1:0] r120_phi [3:0][2:0];
	reg [bw_th-1:0] 	r120_theta [3:0][2:0];
	reg [3:0] 		r120_cpattern [3:0][2:0][3:0];
	reg [bw_fph-1:0] r120_delta_ph [3:0][2:0][5:0];
	reg [bw_th-1:0] 	r120_delta_th [3:0][2:0][5:0]; 
	reg [5:0] 		r120_sign_ph[3:0][2:0];
	reg [5:0] 		r120_sign_th[3:0][2:0];
	reg [bwr:0] 		r120_rank [3:0][2:0];
	reg [seg_ch-1:0] r120_vir [3:0][2:0][3:0]; // valid
	reg [1:0] 		r120_hir [3:0][2:0][3:0]; // bx index
	reg [2:0] 		r120_cir [3:0][2:0][3:0]; // chamber
	reg [3:0] 		r120_sir [3:0][2:0]; // segment
    
    
    reg toggle_r40 = '0;
    reg toggle_r40_prev;
    reg [1:0] patt_idx_in = '0;
    reg [1:0] patt_idx_out;
    
    
    

    // Best Track Outputs
	wire [bw_fph-1:0] w_bt_phi [2:0];
	wire [bw_th-1:0] 	w_bt_theta [2:0];
	wire [3:0] 		w_bt_cpattern [2:0][3:0];
	wire [bw_fph-1:0] w_bt_delta_ph [2:0][5:0];
	wire [bw_th-1:0] 	w_bt_delta_th [2:0][5:0]; 
	wire [5:0] 		w_bt_sign_ph[2:0];
	wire [5:0] 		w_bt_sign_th[2:0];
	wire [bwr:0] 		w_bt_rank [2:0];
	wire [seg_ch-1:0] w_bt_vi [2:0][4:0]; // valid
	wire [1:0] 		w_bt_hi [2:0][4:0]; // bx index
	wire [3:0] 		w_bt_ci [2:0][4:0]; // chamber
	wire [4:0]		w_bt_si [2:0]; // segment

    reg bt_new_bx_flag = '0;
    
    
    
    always @(posedge clk120) begin
        toggle_r40_prev <= toggle_r40;
        
        // Cycle through patt_idx - 1st rising edge after 40MHz edge is phase=1
        if(toggle_r40_prev != toggle_r40)
            patt_idx_in <= 1;
        else if(patt_idx_in == 2)
            patt_idx_in <= 0;
        else
            patt_idx_in <= (patt_idx_in + 1);
        
        // Final pattern deltas are registered to r120 at the end of the 0th clock phase
        if(patt_idx_in == 0)
            bt_new_bx_flag <= 1'b1;
        else
            bt_new_bx_flag <= 1'b0;
            
        
        // Save delta outputs at 120MHz
        for(int izone=0; izone<4; izone++) begin              
            // Save output of deltas [2] first
            r120_phi[izone][2] <= w_phi[izone];
            r120_theta[izone][2] <= w_theta[izone];
            r120_cpattern[izone][2] <= w_cpattern[izone];
            r120_delta_ph[izone][2] <= w_delta_ph[izone];
            r120_delta_th[izone][2] <= w_delta_th[izone];
            r120_sign_ph[izone][2] <= w_sign_ph[izone];
            r120_sign_th[izone][2] <= w_sign_th[izone];
            r120_rank[izone][2] <= w_rank[izone];
            r120_vir[izone][2] <= w_vir[izone];
            r120_hir[izone][2] <= w_hir[izone];
            r120_cir[izone][2] <= w_cir[izone];
            r120_sir[izone][2] <= w_sir[izone];

            // Shift delta outputs
            for(int ipatt=0; ipatt<2; ipatt++) begin
                r120_phi[izone][ipatt] <=       r120_phi[izone][ipatt+1]; 
                r120_theta[izone][ipatt] <=     r120_theta[izone][ipatt+1];
                r120_cpattern[izone][ipatt] <=  r120_cpattern[izone][ipatt+1];
                r120_delta_ph[izone][ipatt] <=  r120_delta_ph[izone][ipatt+1];
                r120_delta_th[izone][ipatt] <=  r120_delta_th[izone][ipatt+1];
                r120_sign_ph[izone][ipatt] <=   r120_sign_ph[izone][ipatt+1];
                r120_sign_th[izone][ipatt] <=   r120_sign_th[izone][ipatt+1];
                r120_rank[izone][ipatt] <=      r120_rank[izone][ipatt+1];
                r120_vir[izone][ipatt] <=       r120_vir[izone][ipatt+1];
                r120_hir[izone][ipatt] <=       r120_hir[izone][ipatt+1];
                r120_cir[izone][ipatt] <=       r120_cir[izone][ipatt+1];
                r120_sir[izone][ipatt] <=       r120_sir[izone][ipatt+1];
            end
        end             
    end
    
    
    always @(posedge clk40) begin
        toggle_r40 <= ~toggle_r40;
        
        bt_phi      <= w_bt_phi;
        bt_theta    <= w_bt_theta;
        bt_cpattern <= w_bt_cpattern;
        bt_delta_ph <= w_bt_delta_ph;
        bt_delta_th <= w_bt_delta_th;
        bt_sign_ph <= w_bt_sign_ph;
        bt_sign_th <= w_bt_sign_th;
        bt_rank <= w_bt_rank;
        bt_vi <= w_bt_vi;
        bt_hi <= w_bt_hi;
        bt_ci <= w_bt_ci;
        bt_si <= w_bt_si;
        
        /*
        for(int izone=0; izone<4; izone++) begin
            // Save previous delta outputs that were registered at 120MHz
            for(int ipatt=0; ipatt<2; ipatt++) begin
                phi[izone][ipatt] <= r120_phi[izone][ipatt+1]; 
                theta[izone][ipatt] <= r120_theta[izone][ipatt+1];
                cpattern[izone][ipatt] <= r120_cpattern[izone][ipatt+1];
                delta_ph[izone][ipatt] <= r120_delta_ph[izone][ipatt+1];
                delta_th[izone][ipatt] <= r120_delta_th[izone][ipatt+1];
                sign_ph[izone][ipatt]  <= r120_sign_ph[izone][ipatt+1];
                sign_th[izone][ipatt]  <= r120_sign_th[izone][ipatt+1];
                rank[izone][ipatt]     <= r120_rank[izone][ipatt+1];
                vir[izone][ipatt] <= r120_vir[izone][ipatt+1];
                hir[izone][ipatt] <= r120_hir[izone][ipatt+1];
                cir[izone][ipatt] <= r120_cir[izone][ipatt+1];
                sir[izone][ipatt] <= r120_sir[izone][ipatt+1];
            end
            
            // Save deltas output directly
            phi[izone][2] <= w_phi[izone];
            theta[izone][2] <= w_theta[izone];
            cpattern[izone][2] <= w_cpattern[izone];
            delta_ph[izone][2] <= w_delta_ph[izone];
            delta_th[izone][2] <= w_delta_th[izone];
            sign_ph[izone][2] <= w_sign_ph[izone];
            sign_th[izone][2] <= w_sign_th[izone];
            rank[izone][2] <= w_rank[izone];
            vir[izone][2] <= w_vir[izone];
            hir[izone][2] <= w_hir[izone];
            cir[izone][2] <= w_cir[izone];
            sir[izone][2] <= w_sir[izone];
        end
        */
        
        
    end
    
    
    wire [bpow:0] 	curr_ph_num [3:0]; // numbers of best ranks [zone][rank number]    
    wire [5:0] 	curr_ph_q [3:0]; // best ranks [zone][rank number]
    
    genvar z;
    generate
        for(z=0; z<4; z=z+1) begin
            assign curr_ph_num[z] = ph_num[z][patt_idx_in];
            assign curr_ph_q[z] = ph_q[z][patt_idx_in];
        end
    endgenerate
    
    
    // 3 Clock delay
    match_ph_segs_serialized i_match_ph_segs_serialized(
        curr_ph_num, curr_ph_q,
        ph, vl,
        th11, th, cpat,
        
        vi, hi, ci, si,  
        ph_match,
        th_match,
        cpat_match,
        ph_qr,
        clk120
    );
    
    // < 2 Clock delay
    deltas_sector_serialized i_deltas_sector_serialized
    (
        vi, hi, ci, si,
        ph_match,
        th_match,
        cpat_match,
        ph_qr,
        th_window,
        th_window_z0,
        two_st_tight_timing,
        
        w_phi,
        w_theta,
        w_cpattern,
        w_delta_ph,
        w_delta_th,
        w_sign_ph,
        w_sign_th,
        w_rank,
        w_vir, w_hir, w_cir, w_sir,
        clk120
    );
    

    // < 2 Clock cycles
	// Registered externally to 40MHz clock
	best_tracks_pipelined bt
    (
        .new_bx_data_flag(bt_new_bx_flag),
        .phi         (r120_phi),
        .theta       (r120_theta),
        .cpattern    (r120_cpattern),
        .delta_ph    (r120_delta_ph),
        .delta_th    (r120_delta_th),
        .sign_ph     (r120_sign_ph),
        .sign_th     (r120_sign_th),
        .rank        (r120_rank),
        .vi          (r120_vir), 
        .hi          (r120_hir), 
        .ci          (r120_cir), 
        .si          (r120_sir),
        
        .bt_phi      (w_bt_phi),
        .bt_theta    (w_bt_theta),
        .bt_cpattern (w_bt_cpattern),
        .bt_delta_ph (w_bt_delta_ph),
        .bt_delta_th (w_bt_delta_th),
        .bt_sign_ph  (w_bt_sign_ph),
        .bt_sign_th  (w_bt_sign_th),
        .bt_rank     (w_bt_rank),
        .bt_vi       (w_bt_vi), 
        .bt_hi       (w_bt_hi), 
        .bt_ci       (w_bt_ci), 
        .bt_si       (w_bt_si),
        
        .clk         (clk120)
    );


	// find_segment outputs, in terms of segments match in zones [zone][pattern_num][station 0-3]
	/*
	reg [seg_ch-1:0] sim_vi [4:0][3:0][3:0]; // valid (for each segment in chamber, so we can identify which th to use later)
	reg [1:0] 		sim_hi [4:0][3:0][3:0]; // bx index
	reg [2:0] 		sim_ci [4:0][3:0][3:0]; // chamber
	reg [3:0] 		sim_si [4:0][3:0]; // segment which has matching ph
	reg [bw_fph-1:0] sim_ph_match [4:0][3:0][3:0]; // matching phi
	reg [bw_th-1:0]	sim_th_match   [4:0][3:0][3:0][seg_ch-1:0]; // matching th, 2 segments 
	reg [3:0] 		sim_cpat_match [4:0][3:0][3:0]; // matching patterns
    reg [5:0] 	sim_ph_qr [4:0][3:0];
    
    always @(posedge clk120) begin 
        sim_vi[4] <= vi;
        sim_hi[4] <= hi;
        sim_ci[4] <= ci;
        sim_si[4] <= si;
        sim_ph_match[4] <= ph_match;
        sim_th_match[4] <= th_match;
        sim_cpat_match[4] <= cpat_match;
        
        for(int ipatt=0; ipatt<4; ipatt++) begin 
            sim_vi[ipatt] <= sim_vi[ipatt+1];
            sim_hi[ipatt] <= sim_hi[ipatt+1];
            sim_ci[ipatt] <= sim_ci[ipatt+1];
            sim_si[ipatt] <= sim_si[ipatt+1];
            sim_ph_match[ipatt] <= sim_ph_match[ipatt+1];
            sim_th_match[ipatt] <= sim_th_match[ipatt+1];
            sim_cpat_match[ipatt] <= sim_cpat_match[ipatt+1];
        end
    end 
    */

endmodule
