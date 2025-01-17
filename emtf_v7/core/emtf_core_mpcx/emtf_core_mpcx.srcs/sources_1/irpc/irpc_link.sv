// TODO:
//  1) set up link alignment inside of rx_deframer
//
//

module irpc_link
(
    mgt_rx.out irpc_rx[0:0], // irpc data from MGT Builder
    
    output csc_lct_mpcx irpc_lcts[1:0], // main output - Data packed into "2 LCT segs"
    output [7:0] link_id,
    output crc_match,
    output link_aligned,
    input clk_40, // LHC clk
    
    input ttc_bc0_del, // Pulse at CSC delay - need to be aligned with this
    input fiber_enable
);
    
    wire [63:0] rx_data [2:0];
    wire rx_valid; // separate bit array is needed because bit-select using lm is illegal

    assign link_aligned = 1'b0; // Set this up
    
    // RX data deframer
    irpc_rx_deframer rxdf
    (
        .reset        (1'b0), // not really needed
        .rxdata_o     (rx_data), // three frames of deframed data
        .valid_o      (rx_valid), // shows when rx data are valid 
        .rxdata_in    (irpc_rx[0].rxdata), // async data input
        .rxcharisk_in (irpc_rx[0].rxcharisk), // async K input
        .link_id      (link_id),
        .crc_match    (crc_match),
        
        .clk_40       (clk_40),
        .clk_250      (irpc_rx[0].rxoutclk), // using rx clocks from each link
        .ttc_bc0_del  (ttc_bc0_del)
    );
    
    always @(*) begin
        if(rx_valid && fiber_enable) begin
            // Seg 0 -> frame 0
            irpc_lcts[0] = rx_data[0][31:0]; // bit [31] is valid, bit [6] isn't used
            irpc_lcts[1] = rx_data[1][31:0];
        end 
        else begin
            irpc_lcts = '{default: '0};
        end
    end     

endmodule