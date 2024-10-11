`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2024 09:01:04 AM
// Design Name: 
// Module Name: best_tracks_stage1
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

module best_tracks_stage1(
    new_bx_data_flag,

     rank,
	 vi, 
     hi, 
     ci, 
     si,
     
     cn_vi_o,
     cn_hi_o,
     cn_ci_o,
     cn_si_o,
     exists_o,
     larger_o,
     
     clk
);

`include "spbits.sv"


    input new_bx_data_flag;

	input [bwr:0] 	   rank [3:0][2:0]; // updated ranks [zone][pattern_num]   
	input [seg_ch-1:0] vi [3:0][2:0][3:0]; // valid [zone][pattern_num][station 0-3]
	input [1:0] 	   hi [3:0][2:0][3:0]; // bx index
	input [2:0] 	   ci [3:0][2:0][3:0]; // chamber
	input [3:0] 	   si [3:0][2:0]; // segment
	
	output reg [seg_ch-1:0] cn_vi_o [3:0][2:0][4:0]; // valid
	output reg [1:0] 		cn_hi_o [3:0][2:0][4:0]; // bx index
	output reg [3:0] 		cn_ci_o [3:0][2:0][4:0]; // chamber
	output reg  		    cn_si_o [3:0][2:0][4:0]; // segment
	
	output reg [23:0] exists_o;
    output reg [23:0] larger_o [24:0];
    
	input clk;

    // [zone][pattern][station]
    wire [6:0] lut_out [3:0][2:0][3:0];

    reg [6:0] 	  zone_to_meid_00 [127:0];
    reg [6:0] 	  zone_to_meid_01 [127:0];
    reg [6:0] 	  zone_to_meid_02 [127:0];
    reg [6:0] 	  zone_to_meid_03 [127:0];
    reg [6:0] 	  zone_to_meid_04 [127:0];
    reg [6:0] 	  zone_to_meid_05 [127:0];
    reg [6:0] 	  zone_to_meid_06 [127:0];
    reg [6:0] 	  zone_to_meid_07 [127:0];
    reg [6:0] 	  zone_to_meid_08 [127:0];
    reg [6:0] 	  zone_to_meid_09 [127:0];
    reg [6:0] 	  zone_to_meid_10 [127:0];
    reg [6:0] 	  zone_to_meid_11 [127:0];
    reg [6:0] 	  zone_to_meid_12 [127:0];
    reg [6:0] 	  zone_to_meid_13 [127:0];
    reg [6:0] 	  zone_to_meid_14 [127:0];
    reg [6:0] 	  zone_to_meid_15 [127:0];
    reg [6:0] 	  zone_to_meid_16 [127:0];
    reg [6:0] 	  zone_to_meid_17 [127:0];
    reg [6:0] 	  zone_to_meid_18 [127:0];
    reg [6:0] 	  zone_to_meid_19 [127:0];
    reg [6:0] 	  zone_to_meid_20 [127:0];
    reg [6:0] 	  zone_to_meid_21 [127:0];
    reg [6:0] 	  zone_to_meid_22 [127:0];
    reg [6:0] 	  zone_to_meid_23 [127:0];
    reg [6:0] 	  zone_to_meid_24 [127:0];
    reg [6:0] 	  zone_to_meid_25 [127:0];
    reg [6:0] 	  zone_to_meid_26 [127:0];
    reg [6:0] 	  zone_to_meid_27 [127:0];
    reg [6:0] 	  zone_to_meid_28 [127:0];
    reg [6:0] 	  zone_to_meid_29 [127:0];
    reg [6:0] 	  zone_to_meid_30 [127:0];
    reg [6:0] 	  zone_to_meid_31 [127:0];
    reg [6:0] 	  zone_to_meid_32 [127:0];
    reg [6:0] 	  zone_to_meid_33 [127:0];
    reg [6:0] 	  zone_to_meid_34 [127:0];
    reg [6:0] 	  zone_to_meid_35 [127:0];
    reg [6:0] 	  zone_to_meid_36 [127:0];
    reg [6:0] 	  zone_to_meid_37 [127:0];
    reg [6:0] 	  zone_to_meid_38 [127:0];
    reg [6:0] 	  zone_to_meid_39 [127:0];
    reg [6:0]      zone_to_meid_40 [127:0];
    reg [6:0] 	  zone_to_meid_41 [127:0];
    reg [6:0] 	  zone_to_meid_42 [127:0];
    reg [6:0] 	  zone_to_meid_43 [127:0];
    reg [6:0] 	  zone_to_meid_44 [127:0];
    reg [6:0] 	  zone_to_meid_45 [127:0];
    reg [6:0] 	  zone_to_meid_46 [127:0];
    reg [6:0] 	  zone_to_meid_47 [127:0];


	
	// chamber ID transcoding LUT
	initial
	begin
	   // fill chamber ID transcoder LUT
	   // contents comes from chamber_ids_zones_to_stations.xlsx
	   $readmemh("zone_to_meid.mem", zone_to_meid_00);
	   $readmemh("zone_to_meid.mem", zone_to_meid_01);
	   $readmemh("zone_to_meid.mem", zone_to_meid_02);
	   $readmemh("zone_to_meid.mem", zone_to_meid_03);
	   $readmemh("zone_to_meid.mem", zone_to_meid_04);
	   $readmemh("zone_to_meid.mem", zone_to_meid_05);
	   $readmemh("zone_to_meid.mem", zone_to_meid_06);
	   $readmemh("zone_to_meid.mem", zone_to_meid_07);
	   $readmemh("zone_to_meid.mem", zone_to_meid_08);
	   $readmemh("zone_to_meid.mem", zone_to_meid_09);
	   $readmemh("zone_to_meid.mem", zone_to_meid_10);
	   $readmemh("zone_to_meid.mem", zone_to_meid_11);
	   $readmemh("zone_to_meid.mem", zone_to_meid_12);
	   $readmemh("zone_to_meid.mem", zone_to_meid_13);
	   $readmemh("zone_to_meid.mem", zone_to_meid_14);
	   $readmemh("zone_to_meid.mem", zone_to_meid_15);
	   $readmemh("zone_to_meid.mem", zone_to_meid_16);
	   $readmemh("zone_to_meid.mem", zone_to_meid_17);
	   $readmemh("zone_to_meid.mem", zone_to_meid_18);
	   $readmemh("zone_to_meid.mem", zone_to_meid_19);
	   $readmemh("zone_to_meid.mem", zone_to_meid_20);
	   $readmemh("zone_to_meid.mem", zone_to_meid_21);
	   $readmemh("zone_to_meid.mem", zone_to_meid_22);
	   $readmemh("zone_to_meid.mem", zone_to_meid_23);
	   $readmemh("zone_to_meid.mem", zone_to_meid_24);
	   $readmemh("zone_to_meid.mem", zone_to_meid_25);
	   $readmemh("zone_to_meid.mem", zone_to_meid_26);
	   $readmemh("zone_to_meid.mem", zone_to_meid_27);
	   $readmemh("zone_to_meid.mem", zone_to_meid_28);
	   $readmemh("zone_to_meid.mem", zone_to_meid_29);
	   $readmemh("zone_to_meid.mem", zone_to_meid_30);
	   $readmemh("zone_to_meid.mem", zone_to_meid_31);
	   $readmemh("zone_to_meid.mem", zone_to_meid_32);
	   $readmemh("zone_to_meid.mem", zone_to_meid_33);
	   $readmemh("zone_to_meid.mem", zone_to_meid_34);
	   $readmemh("zone_to_meid.mem", zone_to_meid_35);
	   $readmemh("zone_to_meid.mem", zone_to_meid_36);
	   $readmemh("zone_to_meid.mem", zone_to_meid_37);
	   $readmemh("zone_to_meid.mem", zone_to_meid_38);
	   $readmemh("zone_to_meid.mem", zone_to_meid_39);
	   $readmemh("zone_to_meid.mem", zone_to_meid_40);
	   $readmemh("zone_to_meid.mem", zone_to_meid_41);
	   $readmemh("zone_to_meid.mem", zone_to_meid_42);
	   $readmemh("zone_to_meid.mem", zone_to_meid_43);
	   $readmemh("zone_to_meid.mem", zone_to_meid_44);
	   $readmemh("zone_to_meid.mem", zone_to_meid_45);
	   $readmemh("zone_to_meid.mem", zone_to_meid_46);
	   $readmemh("zone_to_meid.mem", zone_to_meid_47);
	end

    assign lut_out[0][0][0] = zone_to_meid_00[7'h0  | ci[0][0][0][2:0]];
    assign lut_out[0][0][1] = zone_to_meid_01[7'h8  | ci[0][0][1][2:0]];
    assign lut_out[0][0][2] = zone_to_meid_02[7'h10 | ci[0][0][2][2:0]];
    assign lut_out[0][0][3] = zone_to_meid_03[7'h18 | ci[0][0][3][2:0]];
    assign lut_out[0][1][0] = zone_to_meid_04[7'h0  | ci[0][1][0][2:0]];
    assign lut_out[0][1][1] = zone_to_meid_05[7'h8  | ci[0][1][1][2:0]];
    assign lut_out[0][1][2] = zone_to_meid_06[7'h10 | ci[0][1][2][2:0]];
    assign lut_out[0][1][3] = zone_to_meid_07[7'h18 | ci[0][1][3][2:0]];
    assign lut_out[0][2][0] = zone_to_meid_08[7'h0  | ci[0][2][0][2:0]];
    assign lut_out[0][2][1] = zone_to_meid_09[7'h8  | ci[0][2][1][2:0]];
    assign lut_out[0][2][2] = zone_to_meid_10[7'h10 | ci[0][2][2][2:0]];
    assign lut_out[0][2][3] = zone_to_meid_11[7'h18 | ci[0][2][3][2:0]];
    assign lut_out[1][0][0] = zone_to_meid_12[7'h20 | ci[1][0][0][2:0]];
    assign lut_out[1][0][1] = zone_to_meid_13[7'h28 | ci[1][0][1][2:0]];
    assign lut_out[1][0][2] = zone_to_meid_14[7'h30 | ci[1][0][2][2:0]];
    assign lut_out[1][0][3] = zone_to_meid_15[7'h38 | ci[1][0][3][2:0]];
    assign lut_out[1][1][0] = zone_to_meid_16[7'h20 | ci[1][1][0][2:0]];
    assign lut_out[1][1][1] = zone_to_meid_17[7'h28 | ci[1][1][1][2:0]];
    assign lut_out[1][1][2] = zone_to_meid_18[7'h30 | ci[1][1][2][2:0]];
    assign lut_out[1][1][3] = zone_to_meid_19[7'h38 | ci[1][1][3][2:0]];
    assign lut_out[1][2][0] = zone_to_meid_20[7'h20 | ci[1][2][0][2:0]];
    assign lut_out[1][2][1] = zone_to_meid_21[7'h28 | ci[1][2][1][2:0]];
    assign lut_out[1][2][2] = zone_to_meid_22[7'h30 | ci[1][2][2][2:0]];
    assign lut_out[1][2][3] = zone_to_meid_23[7'h38 | ci[1][2][3][2:0]];
    assign lut_out[2][0][0] = zone_to_meid_24[7'h40 | ci[2][0][0][2:0]];
    assign lut_out[2][0][1] = zone_to_meid_25[7'h48 | ci[2][0][1][2:0]];
    assign lut_out[2][0][2] = zone_to_meid_26[7'h50 | ci[2][0][2][2:0]];
    assign lut_out[2][0][3] = zone_to_meid_27[7'h58 | ci[2][0][3][2:0]];
    assign lut_out[2][1][0] = zone_to_meid_28[7'h40 | ci[2][1][0][2:0]];
    assign lut_out[2][1][1] = zone_to_meid_29[7'h48 | ci[2][1][1][2:0]];
    assign lut_out[2][1][2] = zone_to_meid_30[7'h50 | ci[2][1][2][2:0]];
    assign lut_out[2][1][3] = zone_to_meid_31[7'h58 | ci[2][1][3][2:0]];
    assign lut_out[2][2][0] = zone_to_meid_32[7'h40 | ci[2][2][0][2:0]];
    assign lut_out[2][2][1] = zone_to_meid_33[7'h48 | ci[2][2][1][2:0]];
    assign lut_out[2][2][2] = zone_to_meid_34[7'h50 | ci[2][2][2][2:0]];
    assign lut_out[2][2][3] = zone_to_meid_35[7'h58 | ci[2][2][3][2:0]];
    assign lut_out[3][0][0] = zone_to_meid_36[7'h60 | ci[3][0][0][2:0]];
    assign lut_out[3][0][1] = zone_to_meid_37[7'h68 | ci[3][0][1][2:0]];
    assign lut_out[3][0][2] = zone_to_meid_38[7'h70 | ci[3][0][2][2:0]];
    assign lut_out[3][0][3] = zone_to_meid_39[7'h78 | ci[3][0][3][2:0]];
    assign lut_out[3][1][0] = zone_to_meid_40[7'h60 | ci[3][1][0][2:0]];
    assign lut_out[3][1][1] = zone_to_meid_41[7'h68 | ci[3][1][1][2:0]];
    assign lut_out[3][1][2] = zone_to_meid_42[7'h70 | ci[3][1][2][2:0]];
    assign lut_out[3][1][3] = zone_to_meid_43[7'h78 | ci[3][1][3][2:0]];
    assign lut_out[3][2][0] = zone_to_meid_44[7'h60 | ci[3][2][0][2:0]];
    assign lut_out[3][2][1] = zone_to_meid_45[7'h68 | ci[3][2][1][2:0]];
    assign lut_out[3][2][2] = zone_to_meid_46[7'h70 | ci[3][2][2][2:0]];
    assign lut_out[3][2][3] = zone_to_meid_47[7'h78 | ci[3][2][3][2:0]];

    // Values to hold
    reg [bwr:0] 		rank_r [3:0][2:0];
    reg [seg_ch-1:0]    cn_vi_r [3:0][2:0][4:0]; // valid
    reg [2:0] 		    cn_hi_r [3:0][2:0][4:0]; // bx index
    reg [3:0] 		    cn_ci_r [3:0][2:0][4:0]; // chamber
    reg 				cn_si_r [3:0][2:0][4:0]; // segment
    

    // [zone][pattern][station]
    reg [3:0] real_ch [3:0][2:0][3:0];
    reg [2:0] real_st [3:0][2:0][3:0];
    
    // segment ids reformatted to chamber ids in sector
	//[zone][pattern_num][station 0-4]
	reg [seg_ch-1:0] cn_vi [3:0][2:0][4:0]; // valid
	reg [1:0] 		 cn_hi [3:0][2:0][4:0]; // bx index
	reg [3:0] 		 cn_ci [3:0][2:0][4:0]; // chamber
	reg  		     cn_si [3:0][2:0][4:0]; // segment
	
    reg [1:0] cand_bx [3:0][2:0];
    reg [1:0] cand_bx_r [3:0][2:0];
    

    reg [2:0] h1, h2;
    reg [6:0] ri, rj;
    reg [23:0] good_bx;
    reg [23:0] exists;
    reg [23:0] kill1;
    reg [23:0] larger [24:0];
    reg [2:0] sh_segs;
    
    
    reg [seg_ch-1:0] cn_vi_i, cn_vi_j;
    reg [2:0] 		 cn_hi_i, cn_hi_j;
    reg [3:0] 		 cn_ci_i, cn_ci_j;
    reg 			 cn_si_i, cn_si_j;
    
    

    always @(posedge clk)
	begin

		////// Calculate real station and chamber numbers ///////
		// input segment numbers are in terms of chambers in zone
		// convert them back into chamber ids in sector
		
		// zero segment numbers
		cn_vi = '{default: '0};
		cn_hi = '{default: '0};
		cn_si = '{default: '0};
		cn_ci = '{default: '0};
		
        for (int z = 0; z < 4; z = z+1) begin // zone loop
            for (int n = 0; n < 3; n = n+1) begin // pattern number
                h2 = 3'h0;
                h1 = 3'h0;
                
				for (int s = 0; s < 4; s = s+1) begin // station
				    					
					real_st[z][n][s] = lut_out[z][n][s][6:4]; 
					real_ch[z][n][s] = lut_out[z][n][s][3:0];
					
					cn_vi[z][n][real_st[z][n][s]] = vi[z][n][s];
					cn_hi[z][n][real_st[z][n][s]] = hi[z][n][s];
					cn_si[z][n][real_st[z][n][s]] = si[z][n][s];
					cn_ci[z][n][real_st[z][n][s]] = real_ch[z][n][s];

				    // analyze stub delays, use each track only at the time of second-earliest stub
				   if (vi[z][n][s])
				   begin
					  if (hi[z][n][s] == 2'd2) h2 = h2 + 3'h1; // count stubs delayed by 2 BX
					  if (hi[z][n][s] >= 2'd1) h1 = h1 + 3'h1; // count stubs delayed by 1 BX or more
				   end
				end // for (s = 0; s < 4; s = s+1)

			   // determine proper BX for this track
			   if (h2 >= 3'h2) cand_bx[z][n] = 2'd0; // two stubs in earliest BX, analyze immediately
			   else if (h1 >= 3'h2) cand_bx[z][n] = 2'd1; // second-earliest stub one BX late
			   else cand_bx[z][n] = 2'd2; // second-earliest stub two BXs late
			end
		end
		
		


       larger = '{default: '0};
	   good_bx = '0;
	   exists = '0;
	   
		// simultaneously compare each rank with each
		for (int i = 0; i < 24; i = i+1) begin
			larger[i][i] = 1; // result of comparison with itself
		   // first index loops zone, second loops candidate. Zone loops faster, so we give equal priority to zones
		    if      (i <  12)
			begin
			   ri = rank  [i%4][i/4];
			   if (cand_bx[i%4][i/4] == 2'h0 ) good_bx[i] = 1'b1; // kill this rank if it's not the right BX
			end
		    else
			begin
               ri = rank_r  [(i-12)%4][(i-12)/4];
			   if (cand_bx_r[(i-12)%4][(i-12)/4] == 2'h1 ) good_bx[i] = 1'b1; // kill this rank if it's not the right BX
			end

			for (int j = i+1; j < 24; j = j+1) begin
		       if      (j <  12) rj = rank  [j%4][j/4];
		       else				 rj = rank_r  [(j-12)%4][(j-12)/4];

			   // compare ranks
				if (ri >= rj) larger[i][j] = 1;
 			    else          larger[j][i] = 1;
			end
			// "larger" array shows the result of comparison for each rank

			// track exists if quality != 0 
			exists[i] = (ri != 0);
		end
		
		
		
		// ghost cancellation, over 3 BXs
		kill1 = '0;
		
		for (int i = 0; i < 24; i = i+1) begin // candidate loop
			  for (int j = i+1; j < 24; j = j+1) begin // comparison candidate loop
				 sh_segs = 0;
				 // count shared segments

				 for (int s = 0; s < 5; s = s+1) begin // station loop
					if (i < 12) begin
					   cn_vi_i = cn_vi[i%4][i/4][s]; 
					   cn_ci_i = cn_ci[i%4][i/4][s]; 
					   cn_si_i = cn_si[i%4][i/4][s]; 
					   cn_hi_i = cn_hi[i%4][i/4][s]; 
					end
					else begin
					   cn_vi_i = cn_vi_r[(i-12)%4][(i-12)/4][s]; 
					   cn_ci_i = cn_ci_r[(i-12)%4][(i-12)/4][s]; 
					   cn_si_i = cn_si_r[(i-12)%4][(i-12)/4][s]; 
					   cn_hi_i = cn_hi_r[(i-12)%4][(i-12)/4][s]; 
					end

					if (j < 12) begin
					   cn_vi_j = cn_vi[j%4][j/4][s]; 
					   cn_ci_j = cn_ci[j%4][j/4][s]; 
					   cn_si_j = cn_si[j%4][j/4][s]; 
					   cn_hi_j = cn_hi[j%4][j/4][s]; 
					end
					else begin
					   cn_vi_j = cn_vi_r[(j-12)%4][(j-12)/4][s]; 
					   cn_ci_j = cn_ci_r[(j-12)%4][(j-12)/4][s]; 
					   cn_si_j = cn_si_r[(j-12)%4][(j-12)/4][s]; 
					   cn_hi_j = cn_hi_r[(j-12)%4][(j-12)/4][s]; 
					end
			   
					if (cn_vi_i && cn_vi_j && // both segments valid
						cn_ci_i == cn_ci_j && // from same chamber
						cn_si_i == cn_si_j && // same segment
						cn_hi_i == cn_hi_j // same delay
						) 
					  sh_segs = sh_segs + 3'b1; // increment shared segment counter
				 end // for (s = 0; s < 5; s = s+1)

				 if (sh_segs > 0) begin // a single shared segment means it's ghost
					// kill candidate that has lower rank
					if (larger[i][j]) kill1[j] = 1;
					else kill1[i] = 1;
				 end
			  end // for (j = i+1; j < 36; j = j+1)
		end // for (i = 0; i < 36; i = i+1)
	   
		// remove ghosts according to kill mask
		exists = exists & (~kill1);

	    // remove tracks that are not at correct BX number
	    exists = exists & good_bx;
	   

	   // Register the outputs
	   cn_vi_o <= cn_vi;
       cn_hi_o <= cn_hi;
       cn_ci_o <= cn_ci;
       cn_si_o <= cn_si;
	   exists_o <= exists;
	   larger_o <= larger;
   	
	   if(new_bx_data_flag) begin
	       cand_bx_r <= cand_bx;
	        
	       rank_r <= rank;	       
           cn_vi_r <=  	cn_vi; 
           cn_ci_r <=  	cn_ci;	  
           cn_si_r <=   cn_si;

           // history of delays for each stub
            for (int z = 0; z < 4; z = z+1) begin // zone loop
                for (int n = 0; n < 3; n = n+1) begin // pattern number
                    for (int s = 0; s < 5; s = s+1) begin // station
                       // increase delay of each stub to show by how much it was delayed in total 
                       cn_hi_r [z][n][s] <= cn_hi   [z][n][s] + 3'd1;	  
                    end
                end
            end 
	   end

	end // end always @(posedge clk)




endmodule
