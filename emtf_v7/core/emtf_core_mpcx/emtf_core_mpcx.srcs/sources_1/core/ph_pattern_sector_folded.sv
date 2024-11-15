`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2024 03:59:28 PM
// Design Name: 
// Module Name: ph_pattern_sector_folded
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

module ph_pattern_sector_folded(
    st,
    qcode,
    clk,
    clk160
);

`include "spbits.sv"

	// ph zones [zone][station]
	input [ph_raw_w-1:0] st [3:0][4:1];

	// quality codes output [zone][key_strip]
    output reg [5:0] qcode [3:0][ph_raw_w-1:0];

    input clk;
    input clk160;

	// copy of stations with padding of zeroes on sides, so it's easier to pass to detectors
	// station numbering is different here:
	// 0 == st1
	// 1 == st3
	// 2 == st4
	// st 2 does not need padding
	wire [ph_raw_w + padding_w_st1*2-1:0] stp [3:0][2:0];

	// quality codes from pattern detectors [zone][key_strip]
    reg [5:0] qcode_p [3:0][ph_raw_w-1:0];
    
    
    reg [ph_raw_w-1:0] st_clk160 [4:1];
    reg [ph_raw_w + padding_w_st1*2-1:0] stp_clk160 [2:0];
    wire [5:0] qcode_single_clk160 [ph_raw_w-1:0];
    reg [5:0] qcode_single_clk160_r [ph_raw_w-1:0];
    reg [5:0] qcode_p_clk160 [3:0][ph_raw_w-1:0];
    
	
    logic [1:0] curr_zone = '0; // keep at 2 bits
	
	


    genvar i,z; 
	generate
		for (z = 0; z < 4; z = z+1)
		begin: padding
			// fill padding with zeroes	
			assign stp [z][0][padding_w_st1-1 : 0] = '0;
			assign stp [z][0][ph_raw_w + padding_w_st1*2-1 : ph_raw_w + padding_w_st1] = '0;
			
			assign stp [z][1][padding_w_st3-1 : 0] = '0;
			assign stp [z][1][ph_raw_w + padding_w_st3*2-1 : ph_raw_w + padding_w_st3] = '0;
			
			assign stp [z][2][padding_w_st3-1 : 0] = '0;
			assign stp [z][2][ph_raw_w + padding_w_st3*2-1 : ph_raw_w + padding_w_st3] = '0;
			
			// put station inputs into padded copy
			assign stp [z][0][ph_raw_w + padding_w_st1-1 : padding_w_st1] = st[z][1];
			assign stp [z][1][ph_raw_w + padding_w_st3-1 : padding_w_st3] = st[z][3];
			assign stp [z][2][ph_raw_w + padding_w_st3-1 : padding_w_st3] = st[z][4];
		end
		
		
		for (i = 0; i < ph_raw_w; i = i+1)
        begin : ph_pat_hit
            ph_pattern php
            (
                 .st1 	    (stp_clk160 [0][i+full_pat_w_st1-1 : i]),
                 .st2 	    (st_clk160  [2][i]),
                 .st3 	    (stp_clk160 [1][i+full_pat_w_st3-1 : i]),
                 .st4	    (stp_clk160 [2][i+full_pat_w_st3-1 : i]),
                 .drifttime (0),
                 .foldn	    (curr_zone),
                 .qcode	    (qcode_single_clk160[i]),
                 .clk       (clk160)
            );
        end // block: ph_pat_hit
	endgenerate




    always @(posedge clk160) begin
    
        // Cycle through the zones, order doesn't matter (2'b11 -> 2'b00)
        curr_zone <= curr_zone + 1;
    
        st_clk160 <= st[curr_zone];
        stp_clk160 <= stp[curr_zone];
        
        // Check order in simulation, may need to delay output 1 more clk160
        qcode_single_clk160_r <= qcode_single_clk160;
        case (curr_zone)
            0: qcode_p_clk160[1] <= qcode_single_clk160_r;
            1: qcode_p_clk160[2] <= qcode_single_clk160_r;
            2: qcode_p_clk160[3] <= qcode_single_clk160_r;
            3: qcode_p_clk160[0] <= qcode_single_clk160_r;
            default: qcode_p_clk160[0] <= qcode_single_clk160_r;
        endcase
    end
    
    //  40MHz  |                                       |   qcode for all zones done         |
    //  160MHz | cz0 |  st  | qcode_single | single_r  |   qcode z0  |    z1 |    z2 | z3   |
    
    
    logic [1:0] curr_zone_r40; // keep at 2 bits
    
    always @(posedge clk) begin
        qcode_p <= qcode_p_clk160; // Save qcodes @ 40MHz
        
        curr_zone_r40 <= curr_zone;
    end


	// left, right and center qualities
    reg [5:0] ql, qr, qc;
    
	always @(*)
	begin
		// ghost cancellation logic
		for (int zi = 0; zi < 4; zi = zi+1) // zone loop
		begin
			for (int ri = 0; ri < ph_raw_w; ri = ri+1) // pattern detector loop
			begin
				qc = qcode_p[zi][ri]; // center quality is the current one

				if (ri == 0) // right end - special case
				begin
					ql = qcode_p[zi][ri+1];
					qr = 0; // nothing to the right
				end
				else
				if (ri == ph_raw_w-1) // left end - special case
				begin
					ql = 0; // nothing to the left
					qr = qcode_p[zi][ri-1];
				end
				else // all other patterns
				begin
					ql = qcode_p[zi][ri+1];
					qr = qcode_p[zi][ri-1];
				end

				// cancellation conditions
				if (qc <=  ql || qc <  qr) // this pattern is lower quality than neighbors
				begin
					qc = 0; // cancel
				end

				// put the results into outputs
				qcode[zi][ri] = qc;
			end
		end
	end

endmodule