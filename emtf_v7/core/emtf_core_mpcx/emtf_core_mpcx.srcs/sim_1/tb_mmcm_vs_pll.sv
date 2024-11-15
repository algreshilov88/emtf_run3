`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2024 07:21:33 PM
// Design Name: 
// Module Name: tb_mmcm_vs_pll
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


module tb_mmcm_vs_pll();


reg clk40i = 1'b0;

wire clk40, clk120, clk160;
wire locked;

/*
nn_mmcm nn_mmcm_1
(
    .CLK_IN1  (clk40i),
    .CLK_OUT1 (clk160),
    .CLK_OUT2 (clk40),
    .CLK_OUT3 (clk120),
    .reset    (1'b0),
    .locked   (locked)
); 
*/

/*
usrclk_mmcm usrclk_mmcm_
(
    .CLK_IN1  (clk40i),
    .CLK_OUT1 (clk160),
    .CLK_OUT2 (clk40),
    .CLK_OUT3 (clk120),
    .RESET    (1'b0),
    .LOCKED   (locked)
); 
*/ 
     
clk_wiz_0 DUT
(
    .clk_in1  (clk40i),
    .clk_out1 (clk160),
    .clk_out2 (clk40),
    .clk_out3 (clk120),
    .reset    (1'b0),
    .locked   (locked)
);  

initial begin
    forever begin
        #12 clk40i = ~clk40i;
    end
end


reg [1:0] cnt_clk120_r40i = '0;
reg [1:0] cnt_clk160_r40i = '0;
reg [1:0] cnt_clk120_r40 = '0;
reg [1:0] cnt_clk160_r40 = '0;


reg [1:0] cnt_clk120 = '0;
reg [1:0] cnt_clk160 = '0;

always @(posedge clk120) begin
    if(cnt_clk120 < 2)
        cnt_clk120 <= cnt_clk120 + 1;
    else
        cnt_clk120 <= '0;
end


always @(posedge clk160) begin
    cnt_clk160 <= cnt_clk160 + 1;
end



always @(posedge clk40i) begin
    cnt_clk120_r40i <= cnt_clk120;
    cnt_clk160_r40i <= cnt_clk160;
end

always @(posedge clk40) begin
    cnt_clk120_r40 <= cnt_clk120;
    cnt_clk160_r40 <= cnt_clk160;
end




endmodule
