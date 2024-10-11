`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2024 09:17:59 AM
// Design Name: 
// Module Name: best_tracks_stage2
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

module best_tracks_stage2(
     new_bx_data_flag,
     phi,
     theta,
     cpattern,
     delta_ph,
     delta_th,
     sign_ph,
     sign_th,
     rank,
	 
	 cn_vi, 
     cn_hi, 
     cn_ci, 
     cn_si,
     exists_i,
     larger_i,

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
	input [bw_fph-1:0] phi [3:0][2:0];   // [zone][pattern_num]
	input [bw_th-1:0]  theta [3:0][2:0];
	input [3:0] 	   cpattern [3:0][2:0][3:0]; // [zone][pattern_num][station]

	// [zone][pattern_num], last index: 0=12, 1=13, 2=14, 3=23, 4=24, 5=34
	input [bw_fph-1:0] delta_ph [3:0][2:0][5:0];
	input [bw_th-1:0]  delta_th [3:0][2:0][5:0]; 
	input [5:0] 	   sign_ph[3:0][2:0];
	input [5:0] 	   sign_th[3:0][2:0];
	input [bwr:0] 	   rank [3:0][2:0]; // updated ranks [zone][pattern_num]
	
	// segment ids reformatted to chamber ids in sector
	//[zone][pattern_num][station 0-4]
	input [seg_ch-1:0]   cn_vi [3:0][2:0][4:0]; // valid
	input [1:0] 		 cn_hi [3:0][2:0][4:0]; // bx index
	input [3:0] 		 cn_ci [3:0][2:0][4:0]; // chamber
	input  		         cn_si [3:0][2:0][4:0]; // segment
	
	input [23:0] exists_i;
    input [23:0] larger_i [24:0];
    
	
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
	
	input clk;


	
    reg [bw_fph-1:0]    phi_r [3:0][2:0];
    reg [bw_th-1:0] 	theta_r [3:0][2:0];
    reg [3:0] 		    cpattern_r [3:0][2:0][3:0];
    reg [bw_fph-1:0]    delta_ph_r [3:0][2:0][5:0];
    reg [bw_th-1:0] 	delta_th_r [3:0][2:0][5:0]; 
    reg [5:0] 		    sign_ph_r[3:0][2:0];
    reg [5:0] 		    sign_th_r[3:0][2:0];
    reg [bwr:0] 		rank_r [3:0][2:0];
    reg [seg_ch-1:0]    cn_vi_r [3:0][2:0][4:0]; // valid
    reg [2:0] 		    cn_hi_r [3:0][2:0][4:0]; // bx index
    reg [3:0] 		    cn_ci_r [3:0][2:0][4:0]; // chamber
    reg 				cn_si_r [3:0][2:0][4:0]; // segment
    
    reg [23:0] winner [2:0];
    reg [23:0] exists;
    reg [23:0] larger [24:0];
    reg [5:0] sum;
    
	always @(*)
	begin
        exists = exists_i;
        larger = larger_i;
        
        winner = '{default: '0};
        
        for (int i = 0; i < 24; i = i+1) begin
            if  (exists[i]) larger[i] = larger[i] | (~exists); // if this track exists make it larger than all non-existing tracks
            else  larger[i] = 0; // else make it smaller than anything
        
            // count zeros in the comparison results. The best track will have none, the next will have one, the third will have two.
            sum = 0;
            for (int j = 0; j < 24; j = j+1) 
                if (larger[i][j] == 0) sum = sum + 1; 
        
            if (sum < 3) winner[sum][i] = 1; // assign positional winner codes
        end
		
	   // Zero outputs initially
	   bt_rank = '{default: '0};
	   bt_phi = '{default: '0};
	   bt_theta = '{default: '0};
	   bt_cpattern = '{default: '0};
	   bt_delta_ph = '{default: '0};
	   bt_sign_ph = '{default: '0};
	   bt_delta_th = '{default: '0};
	   bt_sign_th = '{default: '0};
	   bt_vi = '{default: '0};
	   bt_hi = '{default: '0};
	   bt_si = '{default: '0};
	   bt_ci = '{default: '0};
	   

		// multiplex best tracks to outputs according to winner signals
		for (int n = 0; n < 3; n = n+1) // output loop
		begin
			for (int i = 0; i < 12; i = i+1) // winner bit loop
			begin
				if (winner[n][i])
				begin
					bt_rank [n] = bt_rank [n] | rank [i%4][i/4];
					bt_phi[n]   = bt_phi[n]   | phi[i%4][i/4];
					bt_theta[n] = bt_theta[n] | theta[i%4][i/4];
					
					for (int s = 0; s < 4; s = s+1) // station loop
					begin
					   bt_cpattern[n][s] = bt_cpattern[n][s] | cpattern[i%4][i/4][s];
					end
					
					for (int s = 0; s < 6; s = s+1) // delta loop
					begin
						bt_delta_ph [n][s] = bt_delta_ph [n][s] | delta_ph [i%4][i/4][s];
						bt_sign_ph  [n][s] = bt_sign_ph  [n][s] | sign_ph  [i%4][i/4][s];
						bt_delta_th [n][s] = bt_delta_th [n][s] | delta_th [i%4][i/4][s];
						bt_sign_th  [n][s] = bt_sign_th  [n][s] | sign_th  [i%4][i/4][s];
					end
					
					for (int s = 0; s < 5; s = s+1) // station loop
					begin
						bt_vi[n][s] = bt_vi[n][s] | cn_vi[i%4][i/4][s];
						bt_hi[n][s] = bt_hi[n][s] | cn_hi[i%4][i/4][s];
						bt_ci[n][s] = bt_ci[n][s] | cn_ci[i%4][i/4][s];
						bt_si[n][s] = bt_si[n][s] | cn_si[i%4][i/4][s];
					end              
				end
			end
			for (int i = 0; i < 12; i = i+1) // winner bit loop
			begin
				if (winner[n][i+12])
				begin
					bt_rank [n] = bt_rank [n] | rank_r [i%4][i/4];
					bt_phi[n]   = bt_phi[n]   | phi_r[i%4][i/4];
					bt_theta[n] = bt_theta[n] | theta_r[i%4][i/4];
					
					for (int s = 0; s < 4; s = s+1) // station loop
					begin
					   bt_cpattern[n][s] = bt_cpattern[n][s] | cpattern_r[i%4][i/4][s];
					end
					
					for (int s = 0; s < 6; s = s+1) // delta loop
					begin
						bt_delta_ph [n][s] = bt_delta_ph [n][s] | delta_ph_r [i%4][i/4][s];
						bt_sign_ph  [n][s] = bt_sign_ph  [n][s] | sign_ph_r  [i%4][i/4][s];
						bt_delta_th [n][s] = bt_delta_th [n][s] | delta_th_r [i%4][i/4][s];
						bt_sign_th  [n][s] = bt_sign_th  [n][s] | sign_th_r  [i%4][i/4][s];
					end
					
					for (int s = 0; s < 5; s = s+1) // station loop
					begin
						bt_vi[n][s] = bt_vi[n][s] | cn_vi_r[i%4][i/4][s];
						bt_hi[n][s] = bt_hi[n][s] | (cn_hi_r[i%4][i/4][s] - 3'h1); // correct stub delay back to original value
						bt_ci[n][s] = bt_ci[n][s] | cn_ci_r[i%4][i/4][s];
						bt_si[n][s] = bt_si[n][s] | cn_si_r[i%4][i/4][s];
					end              
				end
			end
		end
	   
	end // always @(*)
	
		
		
	always @(posedge clk) begin
	
	   if(new_bx_data_flag) begin
           // keep two-bx history of all inputs    
           phi_r <= 	    phi; 	  
           theta_r <=  	theta;  
           cpattern_r <=   cpattern; 
           delta_ph_r <=   delta_ph; 
           delta_th_r <=   delta_th; 
           sign_ph_r <= 	sign_ph;
           sign_th_r <= 	sign_th;
           rank_r <=   	rank;
           cn_vi_r <=  	cn_vi; 
           cn_ci_r <=  	cn_ci;	  
           cn_si_r <=   cn_si;  
    
           // history of delays for each stub
            for (int z = 0; z < 4; z = z+1) begin // zone loop
                for (int n = 0; n < 3; n = n+1) begin// pattern number
                    for (int s = 0; s < 5; s = s+1) begin // station
                       // increase delay of each stub to show by how much it was delayed in total
                       cn_hi_r [z][n][s] <= cn_hi   [z][n][s] + 3'd1;	  
                    end
                end
            end 
        end        
	end // always @(posedge clk)

endmodule
