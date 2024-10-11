`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/08/2024 12:02:27 PM
// Design Name: 
// Module Name: tb_sp
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


//`define dpath "/home/patrick/Desktop/VivadoProjects/Run3/emtf_tmp/emtf_v7/core/emtf_data/"
`define dpath "../../../../../emtf_data/"


module tb_sp();

    `include "../../sources_1/core/vppc_macros.sv"
    `include "../../sources_1/services/interfaces.sv"
    `include "../../sources_1/mpcx/mpcx_interface.sv"
    `include "../../sources_1/core/spbits.sv"
    
    `param max_ev = 10000; //200000; //220000; //13000;

    `param endcap_p = 1;
    `param sector_p = 1;
    `param rpc_delay = 6; // delay of rpc data relative to csc
    `param ge11_delay = 3; // delay of ge11 data relative to csc
   
    csc_lct_mpcx lct_ii[5:0][8:0][seg_ch-1:0];
    // GEM interfaces [schamber][layer][cluster]
    ge11_cluster ge11_cl [6:0][1:0][7:0]();
   
    // io
    reg [seg_ch-1:0] vpf   [5:0][8:0];
    reg [3:0]        qi    [5:0][8:0][seg_ch-1:0];
    reg [bw_wg-1:0]  wgi   [5:0][8:0][seg_ch-1:0];
    reg [bw_hs-1:0]  hstri [5:0][8:0][seg_ch-1:0];
    reg [3:0] 		 cpati [5:0][8:0][seg_ch-1:0];
    reg [3:0] 		 hmti  [5:0][8:0][seg_ch-1:0];
    reg [3:0] 		 qsesi [5:0][8:0][seg_ch-1:0];
    reg [seg_ch-1:0] lri   [5:0][8:0];

    reg [7:0] ge11_str_i [6:0][1:0][7:0];
    reg [2:0] ge11_prt_i [6:0][1:0][7:0];
    reg [2:0] ge11_csz_i [6:0][1:0][7:0];
    reg [7:0] ge11_vf_i  [6:0][1:0];
   
   
   
   /*
   reg clk40, clk120;
    initial begin
        clk120 = 1'b0;
        forever
            #4 clk120 = ~clk120;
    end

    initial begin
        clk40 = 1'b0;
	forever
	    #12 clk40 = clk40;
    end
    */


    wire clk40, clk120;
    usrclk_mmcm usrclk_mmcm_
	(
        .CLK_IN1  (clki),
        .CLK_OUT1 (),
        .CLK_OUT2 (clk40),
        .CLK_OUT3 (clk120),
        .CLK_OUT4 (),
        .CLK_OUT5 (),
        .RESET    (1'b0),
        .LOCKED   ()
     );  


   genvar 			 gi, gj, gk;
   generate
	  for (gi = 0; gi < 6; gi++) // station loop
		begin
		   for (gj = 0; gj < 9; gj++) // chamber loop
			 begin
				for (gk = 0; gk < 2; gk++) // LCT loop
				  begin
					 assign lct_ii[gi][gj][gk].vf = vpf[gi][gj][gk];
					 assign lct_ii[gi][gj][gk].ql = {qsesi[gi][gj][gk][1], qi[gi][gj][gk][2:0]}; // {1/4 strip=QS, q[2:0]}
					 assign lct_ii[gi][gj][gk].wg = wgi[gi][gj][gk];
					 assign lct_ii[gi][gj][gk].hs = hstri[gi][gj][gk];
					 //assign lct_ii[gi][gj][gk].cp = cpati[gi][gj][gk];
					 // zero out new parameters for now, TBD: need to take these from input file
					 assign lct_ii[gi][gj][gk].lr  = lri[gi][gj][gk];   // left-right flag
					 assign lct_ii[gi][gj][gk].ser = qsesi[gi][gj][gk][0];  // 1/8 strip = ES bit
					 assign lct_ii[gi][gj][gk].cid = cpati[gi][gj][gk];  // CSC ID carries CLCT pattern now
					 assign lct_ii[gi][gj][gk].bc0 = 0;  
					 if (gk == 1)
					 begin
					   // HMT bits are only in LCT1
					   assign lct_ii[gi][gj][gk].cp = {2'b00, hmti[gi][gj][gk][1], 1'b0}; // repurposed hmt[1] bit 
					   assign lct_ii[gi][gj][gk].bx0 = hmti[gi][gj][gk][0]; // repurposed hmt[0] bit
					 end
					 else
					 begin
					   assign lct_ii[gi][gj][gk].cp = 0; 
					   assign lct_ii[gi][gj][gk].bx0 = 0;
					 end
				  end
			 end
		end

	  for (gi = 0; gi < 7; gi++)
		begin
		   for (gj = 0; gj < 2; gj++)
			 begin
				for (gk = 0; gk < 8; gk++)
				  begin
					 assign ge11_cl[gi][gj][gk].str = ge11_str_i [gi][gj][gk];
					 assign ge11_cl[gi][gj][gk].prt = ge11_prt_i [gi][gj][gk];
					 assign ge11_cl[gi][gj][gk].csz = ge11_csz_i [gi][gj][gk];
					 assign ge11_cl[gi][gj][gk].vf  = ge11_vf_i [gi][gj][gk];
				  end
			 end
		end
   endgenerate

   
    // precise parameters
    /*
	 * wire [bw_phi-1:0] phi [2:0];
    wire [bw_eta-1:0] eta [2:0];
    wire [12:0] 	  pt [2:0];
    wire [2:0] 		  sign;
    wire [3:0] 		  modeMem [2:0];
    wire [4:0] 		  etaPT [2:0];
    wire [2:0] 		  FR;
	 */

	reg [1:0]         ge11_cs; // chip select for GE11 prim conv
    reg [8:0] 		  csi [5:0];
    reg [1:0] 		  seli;
    reg [bw_addr-1:0] addri;

    reg [63:0] 		  r_ini; // reg data for memory or register
    wire [63:0] 	  r_outo; // output data from memory or register
    reg 			  wei; // write enable for memory or register
	
    // ph quality codes output [zone][key_strip]
    wire [5:0] 		ph_ranko [3:0][ph_raw_w-1:0];
    // [station][chamber][segment]
    wire [bw_fph-1:0] 	ph   [4:0][8:0][seg_ch-1:0];
    wire [bw_th-1:0] 	th11 [1:0][2:0][th_ch11-1:0];
    wire [bw_th-1:0] 	th   [4:0][8:0][seg_ch-1:0];
    wire [seg_ch-1:0] vl   [4:0][8:0];
    wire [2:0] 		phzvl[4:0][8:0];
	wire [seg_ch-1:0] me11a [1:0][2:0];
	wire [ph_raw_w-1:0] ph_zone [3:0][4:1];

	wire [seg_ch-1:0] 	patt_vi [3:0][2:0][3:0]; // valid
	wire [1:0] 			patt_hi [3:0][2:0][3:0]; // bx index
	wire [2:0] 			patt_ci [3:0][2:0][3:0]; // chamber
	wire [3:0] 			patt_si [3:0][2:0]; // segment

	
    reg 			  clki; // write clock

    // ph_init storage is full-precision now
	// chamber index is 0..11 to include ME11a and b
    reg [bw_fph:0] 	  ph_init0 [15:0]; 
    reg [bw_fph:0] 	  ph_init1 [15:0]; 
    reg [bw_fph:0] 	  ph_init2 [15:0]; 
    reg [bw_fph:0] 	  ph_init3 [15:0];
    reg [bw_fph:0] 	  ph_init4 [15:0]; 
    wire [bw_fph:0] 	  ph_init [4:0][15:0]; // [station][chamber]
    
	// arrays below contains values for each chamber
	// chamber count is ME1=12*2+4(n) ME2,3,4=9*3+3*2(n), total 61 including neighbor sector
    reg [bw_th-1:0]   th_init [60:0]; // chamber origins in th
    reg [bw_ph:0] 	  ph_disp [60:0]; // chamber displacements in ph
    reg [bw_th-1:0]   th_disp [60:0]; // chamber displacements in th
    
    // event storage
    reg [seg_ch-1:0]  valid     [max_ev-1:0][5:0][8:0];
    reg [3:0] 		  quality   [max_ev-1:0][5:0][8:0][seg_ch-1:0];
    reg [6:0] 		  wiregroup [max_ev-1:0][5:0][8:0][seg_ch-1:0];
    reg [bw_hs-1:0]   hstrip    [max_ev-1:0][5:0][8:0][seg_ch-1:0];
    reg [3:0] 		  clctpat   [max_ev-1:0][5:0][8:0][seg_ch-1:0];
    reg [1:0] 		  hmt       [max_ev-1:0][5:0][8:0][seg_ch-1:0];
    reg [1:0] 		  qses      [max_ev-1:0][5:0][8:0][seg_ch-1:0];
    reg [seg_ch-1:0]  lr        [max_ev-1:0][5:0][8:0];
    
    // [subsector][chamber][hit]
    reg [10:0] rpc_ph [max_ev+rpc_delay-1:0][6:0][5:0][seg_ch-1:0];
    reg [4:0]  rpc_th [max_ev+rpc_delay-1:0][6:0][5:0][seg_ch-1:0];

    // [scham=link][layer][cluster]
    reg [7:0] ge11_str [max_ev+ge11_delay-1:0][6:0][1:0][7:0];
    reg [2:0] ge11_prt [max_ev+ge11_delay-1:0][6:0][1:0][7:0];
    reg [2:0] ge11_csz [max_ev+ge11_delay-1:0][6:0][1:0][7:0];

    integer 	      iadr = 0, s = 0, i = 0, pi, j = 0, sn, c;
    reg [15:0] 		  v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13;
    reg [2:0] 		  pr_cnt      [6:0][8:0];
    reg [2:0] 		  pr_cnt_rpc  [6:0][8:0];
    reg [2:0] 		  pr_cnt_ge11 [6:0][8:0]; // second index wider than needed, but OK
    integer 		  _event;
	reg [9:0] 		  _bx_jitter; 		  
    reg [1:0] 		  _endcap;
    reg [2:0] 		  _sector;
    reg [1:0] 		  _subsector;
    reg [2:0] 		  _station, old_station;
    reg [3:0] 		  _cscid;
    reg [3:0] 		  _bend;
    reg [10:0] 		  _halfstrip;
    reg [1:0]		  _valid;
    reg [3:0] 		  _quality;
    reg [3:0] 		  _pattern;
    reg [6:0] 		  _wiregroup;
    reg [1:0]         _hmt;
    reg [1:0]         _qses;
    reg               _lr;
    integer 	      ist, icid, ipr, code, iev, im, iz, ir;
    reg [800-1:0] 	  line;
    integer 	      in, best_tracks, vllut_in, sim_out, best_tracks_short, nn_out;
    integer 	      stat;
    reg [31:0] 		  ev = 0;
    reg [4:0] 		  good_ev = 0;
    integer 	      good_ev_cnt = 0;
    integer 	      found_tr = 0;
    integer 	      found_cand = 0;	      
    integer 	      st;
    integer 	      st_cnt; // station count
	integer 		  iseg;
	integer 		  zi, si, ip, is;

    time 			  begin_time, end_time, elapsed_time;
    reg [11:0] 		  tphi, a, b, d;
	reg 			  pts;
	// numbers of best ranks [zone][num]
	wire [bpow:0] ph_num [3:0][2:0]; 
	// best ranks [zone][num]
	wire [bwr-1:0] ph_q [3:0][2:0]; 
	wire [bw_fph-1:0]	ph_match [3:0][2:0][3:0]; // matching ph
	wire [bw_th-1:0]	th_match   [3:0][2:0][3:0][seg_ch-1:0]; // matching th, 2 segments 
	wire [bw_th-1:0]	th_match11 [1:0][2:0][th_ch11-1:0]; // matching th for ME11 (station 0 only), 4 segments (due to th duplication)
	// precise phi and theta of best tracks
	// [best_track_num]
	wire [bw_fph-1:0] 	bt_phi [2:0];
	wire [bw_th-1:0] 	bt_theta [2:0];
	wire [3:0] 			bt_cpattern [2:0][3:0];
	// ph and th deltas from best stations
	// [best_track_num], last index: [0] - best pair of stations, [1] - second best pair
	wire [bw_fph-1:0] 	bt_delta_ph [2:0][5:0];
	wire [bw_th-1:0] 	bt_delta_th [2:0][5:0]; 
	wire [5:0] 			bt_sign_ph[2:0];
	wire [5:0] 			bt_sign_th[2:0];
	// ranks [best_track_num]
	wire [bwr:0] 		bt_rank [2:0];
	// segment IDs
	// [best_track_num][station 0-3]
	wire [seg_ch-1:0] 	bt_vi [2:0][4:0]; // valid
	wire [1:0] 			bt_hi [2:0][4:0]; // bx index
	wire [3:0] 			bt_ci [2:0][4:0]; // chamber
	wire [4:0] 			bt_si [2:0]; // segment
    reg lat_test; // latency test mode
    
    wire [7:0] gmt_phi [2:0]; // phi for gmt
    wire [8:0] gmt_eta [2:0]; // eta for gmt
    wire        en_single = 1'b0;
   
   reg [31:0] 	ptlut [536870912-1:0]; // 1/2G x 32 bits, each word carries two 9-bit values
   integer 		ptfile;
   reg [31:0] 	pt_word;
   reg [31:0] 	pt_word_rev;
   reg [8:0] 	pt_value;
`define brev(a) {a[7:0], a[15:8], a[23:16], a[31:24]}

   wire [3:0] gmt_qlt [2:0]; // quality for gmt
   wire [2:0] gmt_crg;
   wire [29:0] ptlut_addr [2:0]; // ptlut addresses for best 3 muons
   wire [31:0] ptlut_cs [2:0]; // pre-decoded chip selects
   wire [2:0]  ptlut_addr_val; // ptlut address valid flags
   reg [63:0] cppf_rxd [6:0][2:0]; // cppf rx data, 3 frames x 64 bit, for 7 links
   wire [6:0] cppf_rx_valid = 7'h7f; // cprx data valid flags, always valid

	wire [7:0] nn_pt [2:0]; // NN PT value
	wire [2:0] nn_pt_v; // NN valid flag for PT
	wire [1:0] nn_d0 [2:0]; // NN PT value
	wire [2:0] nn_d0_v; // NN valid flag for PT
   

   // 
   reg       endcap; // 0=ME+ 1=ME-
   reg [2:0] sector; // sector #-1
   reg [20*8-1:0] fes_str, fest_str;
   wire [1:0] hmt_out; // {out_of_time, in_time}
`define fes fes_str
`define fest fest_str
   

   wire [63:0] 	  core_config;
	assign core_config[bw_th-1:0] = 8;// wire [bw_th-1:0] th_window
    assign core_config[11:8]      = 9;// wire [3:0] delay_two_mu
    assign core_config[12]        = 0;// wire en_single
    assign core_config[13]        = 0;// wire en_two_mu
    assign core_config[14]        = 0;// wire low_th_promote
    assign core_config[15]        = 1;// wire use_rpc
	assign core_config[22:16]     = 4;// wire [bw_th-1:0] th_window_z0
    assign core_config[23]        = 1;// wire two_st_tight_timing
    assign core_config[30:27]     = 5; // HMT delay
	
	integer 	   ibx,ich,isg, ii, kp;
    // Instantiate the Unit Under Test (UUT)
    sp uut 
		(
		 .lct_i (lct_ii),
		 .ge11_cl (ge11_cl),
		 .cppf_rxd (cppf_rxd),
		 .cppf_rx_valid (cppf_rx_valid),
		 .pcs_cs   (csi), 
		 .ge11_cs  (ge11_cs),
		 .sel      (seli), 
		 .addr     (addri), 
		 .r_in     (r_ini), 
		 .r_out    (r_outo), 
		 .we       (wei),

		 .bt_phi (bt_phi),
		 .bt_theta (bt_theta),
		 .bt_cpattern (bt_cpattern),
		 .bt_delta_ph (bt_delta_ph),
		 .bt_delta_th (bt_delta_th),
		 .bt_sign_ph (bt_sign_ph),
		 .bt_sign_th (bt_sign_th),
		 .bt_rank (bt_rank),
		 .bt_vi (bt_vi), 
		 .bt_hi (bt_hi), 
		 .bt_ci (bt_ci), 
		 .bt_si (bt_si),

		 .ptlut_addr (ptlut_addr),
		 .ptlut_cs (ptlut_cs),
		 .ptlut_addr_val (ptlut_addr_val),
		 
		 .gmt_phi (gmt_phi),
		 .gmt_eta (gmt_eta),
		 .gmt_qlt (gmt_qlt),
		 .gmt_crg (gmt_crg),
         .hmt_out (hmt_out),

	     .nn_pt   (nn_pt  ), // NN PT value
	     .nn_pt_v (nn_pt_v), // NN valid flag for PT
	     .nn_d0   (nn_d0  ), // NN D0 value
	     .nn_d0_v (nn_d0_v), // NN valid flag for D0

		 .clk      (clk40),
		 .control_clk(clki), // use main clock for control as well
		 .clk120   (clk120),
		 .endcap (endcap),
		 .sector (sector),
		 .lat_test (lat_test),
		 .core_config (core_config) // en_2mu, en_single, delay_2mu, th_window 
//		 .core_config ({1'b0, 1'b0, 4'h9, 8'h8}) // en_2mu, en_single, delay_2mu, th_window 
		 );


    // temporary LUTs for th_mem, data need to be reformatted for actual storage in firmware LUTs
    reg [7:0] ge11_th_tmp [111:0]; // 112 words by 8 bit = 14 words by 64 bits
    reg [63:0] ge11_th_u64;
    integer wi, wj;
   
   `int 	   ph_high_prec, ph_low_prec, ph_zone_phi;
    `int k;
    `int gz, gn, gs, f, stb;
   integer 			   first_stub, station_cnt;
   integer tmb_revert[5:0][8:0];// [station][chamber]

    reg [3:0] nn_mode_r [2:0];
    reg [2:0] nn_valid_in;
    reg [1:0] mux_phase_print [2:0] = '{2'h2, 2'h0, 2'h1};
    reg [17:0] nn_input [2:0][22:0] = '{
        '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    };
    

    initial 
		begin
			//sim_out = $fopen("sp_tf.out","w");
			sim_out = $fopen({`dpath,"/sp_tf_2nd.out"}, "w");//
			//sim_out = $fopen("/home/hvuser/mrcarver/ConvTest/S1R1_closer.out", "w");//


		   endcap = endcap_p - 1;
		   sector = sector_p - 1;
		   $sformat (fes_str , "_endcap_%0d_sec_%0d_", endcap_p, sector_p);
		   $sformat (fest_str, "_endcap_%0d_sect_%0d", endcap_p, sector_p);
		   
		   $fwrite (sim_out, "endcap: %d sector: %d strings: %s %s\n", endcap, sector, `fes, `fest);
		   
            // write parameters to primitive converters
			`include "fill_params.sv"
			`include "fill_params_ge11.sv"
			//  tmb_revert[0][0] = uut.pcs.station11[0].csc11[0].pc11.tmb_revert;
			//	tmb_revert[0][1] = uut.pcs.station11[0].csc11[1].pc11.tmb_revert;
			//	tmb_revert[0][2] = uut.pcs.station11[0].csc11[2].pc11.tmb_revert;
			//	tmb_revert[1][0] = uut.pcs.station11[1].csc11[0].pc11.tmb_revert;
			//	tmb_revert[1][1] = uut.pcs.station11[1].csc11[1].pc11.tmb_revert;
			//	tmb_revert[1][2] = uut.pcs.station11[1].csc11[2].pc11.tmb_revert;
												
			tmb_revert[0][3] = uut.pcs.station12[0].csc12[3].pc12.tmb_revert;
			tmb_revert[0][4] = uut.pcs.station12[0].csc12[4].pc12.tmb_revert;
			tmb_revert[0][5] = uut.pcs.station12[0].csc12[5].pc12.tmb_revert;
			tmb_revert[0][6] = uut.pcs.station12[0].csc12[6].pc12.tmb_revert;
			tmb_revert[0][7] = uut.pcs.station12[0].csc12[7].pc12.tmb_revert;
			tmb_revert[0][8] = uut.pcs.station12[0].csc12[8].pc12.tmb_revert;
			tmb_revert[1][3] = uut.pcs.station12[1].csc12[3].pc12.tmb_revert;
			tmb_revert[1][4] = uut.pcs.station12[1].csc12[4].pc12.tmb_revert;
			tmb_revert[1][5] = uut.pcs.station12[1].csc12[5].pc12.tmb_revert;
			tmb_revert[1][6] = uut.pcs.station12[1].csc12[6].pc12.tmb_revert;
			tmb_revert[1][7] = uut.pcs.station12[1].csc12[7].pc12.tmb_revert;
			tmb_revert[1][8] = uut.pcs.station12[1].csc12[8].pc12.tmb_revert;

			tmb_revert[2][0] = uut.pcs.station234[2].csc[0].pc.tmb_revert;
			tmb_revert[2][1] = uut.pcs.station234[2].csc[1].pc.tmb_revert;
			tmb_revert[2][2] = uut.pcs.station234[2].csc[2].pc.tmb_revert;
			tmb_revert[2][3] = uut.pcs.station234[2].csc[3].pc.tmb_revert;
			tmb_revert[2][4] = uut.pcs.station234[2].csc[4].pc.tmb_revert;
			tmb_revert[2][5] = uut.pcs.station234[2].csc[5].pc.tmb_revert;
			tmb_revert[2][6] = uut.pcs.station234[2].csc[6].pc.tmb_revert;
			tmb_revert[2][7] = uut.pcs.station234[2].csc[7].pc.tmb_revert;
			tmb_revert[2][8] = uut.pcs.station234[2].csc[8].pc.tmb_revert;
			tmb_revert[3][0] = uut.pcs.station234[3].csc[0].pc.tmb_revert;
			tmb_revert[3][1] = uut.pcs.station234[3].csc[1].pc.tmb_revert;
			tmb_revert[3][2] = uut.pcs.station234[3].csc[2].pc.tmb_revert;
			tmb_revert[3][3] = uut.pcs.station234[3].csc[3].pc.tmb_revert;
			tmb_revert[3][4] = uut.pcs.station234[3].csc[4].pc.tmb_revert;
			tmb_revert[3][5] = uut.pcs.station234[3].csc[5].pc.tmb_revert;
			tmb_revert[3][6] = uut.pcs.station234[3].csc[6].pc.tmb_revert;
			tmb_revert[3][7] = uut.pcs.station234[3].csc[7].pc.tmb_revert;
			tmb_revert[3][8] = uut.pcs.station234[3].csc[8].pc.tmb_revert;
			tmb_revert[4][0] = uut.pcs.station234[4].csc[0].pc.tmb_revert;
			tmb_revert[4][1] = uut.pcs.station234[4].csc[1].pc.tmb_revert;
			tmb_revert[4][2] = uut.pcs.station234[4].csc[2].pc.tmb_revert;
			tmb_revert[4][3] = uut.pcs.station234[4].csc[3].pc.tmb_revert;
			tmb_revert[4][4] = uut.pcs.station234[4].csc[4].pc.tmb_revert;
			tmb_revert[4][5] = uut.pcs.station234[4].csc[5].pc.tmb_revert;
			tmb_revert[4][6] = uut.pcs.station234[4].csc[6].pc.tmb_revert;
			tmb_revert[4][7] = uut.pcs.station234[4].csc[7].pc.tmb_revert;
			tmb_revert[4][8] = uut.pcs.station234[4].csc[8].pc.tmb_revert;
			tmb_revert[4][0] = uut.pcs.station234[4].csc[0].pc.tmb_revert;

			
			//    tmb_revert[5][0] = uut.pcs.pcn11.tmb_revert;
			tmb_revert[5][1] = uut.pcs.cscn[1].pcn.tmb_revert;
			tmb_revert[5][2] = uut.pcs.cscn[2].pcn.tmb_revert;
			tmb_revert[5][3] = uut.pcs.cscn[3].pcn.tmb_revert;
			tmb_revert[5][4] = uut.pcs.cscn[4].pcn.tmb_revert;
			tmb_revert[5][5] = uut.pcs.cscn[5].pcn.tmb_revert;
			tmb_revert[5][6] = uut.pcs.cscn[6].pcn.tmb_revert;
			tmb_revert[5][7] = uut.pcs.cscn[7].pcn.tmb_revert;
			tmb_revert[5][8] = uut.pcs.cscn[8].pcn.tmb_revert;

		   // read PT LUT
		   //ptfile = $fopen ({`dpath, "LUT_v9_19Apr23_full.dat"}, "rb");
		   //$fread (ptlut, ptfile);
		   //$fclose (ptfile);
		   //$readmemh({`dpath, "LUT_v9_19Apr23_full.hex"}, ptlut); // slow method, other one crashes
			
			// initialize event storage
			for (iev = 0; iev < max_ev; iev=iev+1)
			begin
				for (ist = 0; ist < 6; ist=ist+1) 
					for (icid = 0; icid < 9; icid=icid+1)
						for (ipr = 0; ipr < seg_ch; ipr=ipr+1)
						begin
							valid    [iev][ist][icid][ipr] = 1'b0;
							quality  [iev][ist][icid][ipr] = 4'b0;
							wiregroup[iev][ist][icid][ipr] = 7'b0;
							hstrip   [iev][ist][icid][ipr] = 8'b0;
							qses     [iev][ist][icid][ipr] = 2'b0;
							lr       [iev][ist][icid][ipr] = 1'b0;
							clctpat  [iev][ist][icid][ipr] = 4'b0;
							hmt      [iev][ist][icid][ipr] = 2'b0;
						end

				for (ist = 0; ist < 7; ist=ist+1) // rpc subsector
					for (icid = 0; icid < 6; icid=icid+1) // rpc chamber
						for (ipr = 0; ipr < seg_ch; ipr=ipr+1) // hit
						begin
							rpc_ph [iev+rpc_delay][ist][icid][ipr] = 11'h7ff;
							rpc_th [iev+rpc_delay][ist][icid][ipr] = 5'h1f;
						end
			   
				for (ist = 0; ist < 7; ist=ist+1) // ge11 schamber
					for (icid = 0; icid < 2; icid=icid+1) // ge11 layer
						for (ipr = 0; ipr < 8; ipr=ipr+1) // ge11 cluster
						begin
							ge11_str [iev+ge11_delay][ist][icid][ipr] = 8'hff;
							ge11_prt [iev+ge11_delay][ist][icid][ipr] = 3'h7;
							ge11_csz [iev+ge11_delay][ist][icid][ipr] = 3'h7;
						end
			end
			

			// read events - (fill event storage)
			in = $fopen({`dpath, "data.dat"}, "r");

			
			if (in == 0) 
			begin
			     $fwrite(sim_out, "cannot open input file\n");
			     $finish;
			end
			_event = 0;
			//			$fwrite(sim_out, "in: %h _event: %h\n", in, _event);
			while (!$feof(in) && _event < max_ev)
			begin
				// read line
				code = $fgets(line, in);
				//                $fwrite (sim_out, "%h\n", line);
				// read values
				v0 = 0; v1 = 0; v2 = 0; v3 = 0; v4 = 0; v5 = 0; v6 = 0; v7 = 0; v8 = 0; v9 = 0; v10 = 0; v11 = 0; v12 = 0; v13 = 0;
				sn = $sscanf(line, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d", 
							 v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13);
				//$fwrite(sim_out, "code %d read %d items %d %d %d %d %d %d %d %d %d %d %d %d %d\n", code, sn,
				//	    v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12);
				case (sn)
					1: 
						begin	// end of event
							// clean primitive counters
							for (i = 0; i < 7; i=i+1) 
							     for (j = 0; j < 9; j=j+1)
							     begin
								    pr_cnt[i][j] = 0;
								    pr_cnt_rpc[i][j] = 0;
								    pr_cnt_ge11[i][j] = 0;
							     end
							j = 0;
							_event = _event + 1;
							first_stub = 1;
							station_cnt = 0;
							//$fwrite(sim_out, "End of event %d\n", _event);
						end
					12, 14: 
						begin	// primitive
						    //$fwrite (sim_out, "entering primitive *****************************************\n");
							_hmt = v0;	
							_endcap = v1;
							_sector = v2;
							_subsector = v3;
							_station = v4;
							if (_station == 1 && _subsector == 1) _station = 0;
							_valid = v5;	
							_quality = v6;
							_pattern = v7;
							_wiregroup = v8;
							_cscid = v9;	
							_bend = v10;
							_halfstrip = v11;
							if (sn == 14) _qses = v12; // updated format with qs, es, lr bits
							else _qses = 0;
							if (sn == 14) _lr = v13; // updated format with qs, es, lr bits
							else _lr = 0;

							// code that adds jitter, for BXA checks
							if (first_stub == 1) old_station = _station;
							first_stub = 0;
							
							if (old_station != _station)
								station_cnt = station_cnt+1;

							_bx_jitter = 2;
							if (station_cnt <= 1)
							begin
								//								_bx_jitter = 0;
							end

							// increase stub counter only when station changes
							old_station = _station;
							// end of BX jitter code

							//$fwrite(sim_out, "primitive: subsec: %d  stat: %d  val: %d  hs: %h  wg: %h  q: %h  cscid: %d \n",
									//_subsector, _station, _valid, _halfstrip, _wiregroup, _quality, _cscid);
							
							// copy data to the corresponding input

							if (_endcap == endcap_p && _sector == sector_p)
							begin
								if (_valid == 1) // csc
								begin
									_cscid = _cscid-1; // CSC IDs start from 1 in the input files
									if (_station > 5) $fwrite(sim_out, "bad station: %d, event: %d\n", _station, _event);
									else 
										if (_cscid > 8) $fwrite(sim_out, "bad cscid: %d, station: %d, event: %d\n", _cscid, _station, _event);
										else
											//if (_cscid == 0) $fwrite(sim_out, "removing cscid=1: %d, station: %d, event: %d\n", _cscid, _station, _event);
											//else 
												if (pr_cnt[_station][_cscid] >= seg_ch)
												begin
													$fwrite(sim_out, "bad segment index. event: %d, index: %d, station: %d, cscid: %d\n",
															_event, pr_cnt[_station][_cscid], _station, _cscid);
												end
												else
												begin
													valid    [_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _valid;
													quality  [_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _quality;
													wiregroup[_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _wiregroup;
													hstrip   [_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _halfstrip;
													qses     [_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _qses;
													lr       [_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _lr;
													clctpat  [_event + _bx_jitter][_station][_cscid][pr_cnt[_station][_cscid]] = _pattern;
													hmt      [_event + _bx_jitter][_station][_cscid][1] = _hmt; // HMT always and only in LCT1, see CMS note DN-20-016
													// increase primitive counter
													pr_cnt[_station][_cscid] = pr_cnt[_station][_cscid] + 1;
												end // else: !if(pr_cnt[_station][_cscid] >= seg_ch)
								end // if (_valid == 1)
								else if (_valid == 2) // rpc
								begin
									if (pr_cnt_rpc[_station][_cscid] >= seg_ch)
									begin
										$fwrite(sim_out, "bad RPC segment index. event: %d, index: %d, station: %d, cscid: %d\n",
												_event, pr_cnt_rpc[_station][_cscid], _station, _cscid);
									end
									else
									begin
										//$fwrite (sim_out, "rpc hit: evt: %d rpc_subsect: %d ch: %d phi: %d th: %d TruePhi: %d\n", _event, _station, _cscid, _halfstrip, _wiregroup, 4*_halfstrip);
										rpc_ph [_event + _bx_jitter + rpc_delay][_station][_cscid][pr_cnt_rpc[_station][_cscid]] = _halfstrip; // actually carries phi
										rpc_th [_event + _bx_jitter + rpc_delay][_station][_cscid][pr_cnt_rpc[_station][_cscid]] = _wiregroup; // actually carries theta
										// increase primitive counter
										pr_cnt_rpc[_station][_cscid] = pr_cnt_rpc[_station][_cscid] + 1;
									end // else: !if(pr_cnt_rpc[_station][_cscid] >= seg_ch)
								end // if (_valid == 2)
								else if (_valid == 3) // GE11
								begin
									if (pr_cnt_ge11[_station][_cscid] >= 2) // can only use two clusters per chamber
									begin
										$fwrite(sim_out, "bad GE11 segment index. event: %4d, index: %1d, schamber: %1d, layer: %1d\n",
												_event, pr_cnt_rpc[_station][_cscid], _station, _cscid);
									end
									else
									begin
										//$fwrite (sim_out, "GE11 hit: sch: %d ly: %d str: %d prt: %d csz: %d\n", _station, _cscid, _halfstrip, _wiregroup, _pattern);
                                      	//                                           [schamber][ layer][         cluster               ]
										ge11_str [_event + _bx_jitter + ge11_delay][_station][_cscid][pr_cnt_ge11[_station][_cscid]*4] = _halfstrip; // actually carries strip
										ge11_prt [_event + _bx_jitter + ge11_delay][_station][_cscid][pr_cnt_ge11[_station][_cscid]*4] = _wiregroup; // actually carries partition
										ge11_csz [_event + _bx_jitter + ge11_delay][_station][_cscid][pr_cnt_ge11[_station][_cscid]*4] = _pattern;   // actually carries cluster size
										// cluster indexes above are filled 0, then 4, because GE11 fills clusters like that. Current EMTF logic can only use 0 and 4, so ignore all others
										// increase cluster counter
										pr_cnt_ge11[_station][_cscid]++;
									end // else: !if(pr_cnt_rpc[_station][_cscid] >= seg_ch)
								end // if (_valid == 2)
							end // if (_endcap == endcap_p || _sector == sector_p)
							
						end
				endcase
			end


			seli = 0;
			addri = 0;
			r_ini = 0;
			wei = 0;
			clki = 0;

			elapsed_time = 0;

			best_tracks = $fopen({`dpath, "/best_tracks_2nd.out"}, "w");
			nn_out      = $fopen({`dpath, "/nn.out"}, "w");
			best_tracks_short = $fopen({`dpath, "/best_tracks_short_2nd.out"}, "w");

            // give MMCM time to start, around 4.6 uS 
			for (i = 0; i < 250; i = i+1)
			begin
				for (j = 0; j < 2; j = j+1)
				begin
					`clk_drive(clki, j);
					`__top_module__
						end
            end
			
			for (i = 0; i < 200 + max_ev-1; i = i+1)
			begin

				wei = 0;
				for (k = 0; k < 5; k = k+1)
				begin
					
					csi[k] = 0;
					for (j = 0; j < 9; j = j+1)
					begin
						for (si = 0; si < seg_ch; si = si+1)
						begin
							qi[k][j][si] = 0;
							wgi[k][j][si] = 0;
							hstri[k][j][si] = 0;
							cpati[k][j][si] = 0;
							hmti[k][j][si] = 0;
							qsesi[k][j][si] = 0;
							lri[k][j][si] = 0;
						end
					end
				end

			   	// Load the event data into sp inputs
				if (i > 0)
				begin
					good_ev = 0;
					st_cnt = 0;
					for (ist = 0; ist < 6; ist=ist+1) // station
					begin
						for (icid = 0; icid < 9; icid=icid+1) // chamber id
						begin
							for (si = 0; si < seg_ch; si = si+1) // stub
							  begin
								 vpf  [ist][icid][si] = valid    [ev][ist][icid][si];
								 qi   [ist][icid][si] = quality  [ev][ist][icid][si];
								 wgi  [ist][icid][si] = wiregroup[ev][ist][icid][si];
								 hstri[ist][icid][si] = hstrip   [ev][ist][icid][si];
								 cpati[ist][icid][si] = clctpat  [ev][ist][icid][si];
								 hmti [ist][icid][si] = hmt      [ev][ist][icid][si];
								 qsesi[ist][icid][si] = qses     [ev][ist][icid][si];
								 lri  [ist][icid][si] = lr       [ev][ist][icid][si];
								 if (vpf [ist][icid][si] == 1'b1)
								 begin
								 
									$fwrite(sim_out, "CSC_RAW: ev: %4d st: %1d ch: %1d q: %h wg: %3d hs: %3d hmt: %h qses: %h tmb_revert: %1d cpatt: %0d\n",
								 			ev, ist, icid, qi [ist][icid][si], wgi [ist][icid][si], hstri [ist][icid][si], hmti [ist][icid][si],
								 			qsesi[ist][icid][si], tmb_revert[ist][icid], cpati[ist][icid][si]);
								 end
								// check if there is chamber data, update good event station mask
								if (qi  [ist][icid][si] > 0) good_ev[ist] = 1;
							end
						end // for (icid = 0; icid < 9; icid=icid+1)
						// count stations in this event
						if (good_ev[ist]) st_cnt = st_cnt + 1;
					end

					for (ist = 0; ist < 7; ist=ist+1) // subsector
					begin
						for (icid = 0; icid <= 5; icid=icid+1) // rpc chamber
						begin
							for (si = 0; si < seg_ch; si = si+1) // hit
							begin
							   f = icid/2; // frame
							   stb = ((icid%2)*2+si); // stub
							   cppf_rxd[ist][f][stb*16 +: 16] = {rpc_th [ev][ist][icid][si], rpc_ph [ev][ist][icid][si]};
							   //cppf_rxd[ist][f][stb*16 +: 16] = 16'hffff;
                               if( (rpc_th [ev][ist][icid][si] != '1) && (rpc_ph [ev][ist][icid][si])) begin
                                    $fwrite(sim_out, "RPC_RAW: phi: %d  th: %d\n", rpc_th [ev][ist][icid][si], rpc_ph [ev][ist][icid][si]);
                               end
							end
						end // for (icid = 0; icid < 9; icid=icid+1)
						// count stations in this event
						if (good_ev[ist]) st_cnt = st_cnt + 1;
					end

					for (ist = 0; ist < 7; ist=ist+1) // schamber
					begin
						for (icid = 0; icid < 2; icid=icid+1) // layer
						begin
							for (si = 0; si < 8; si = si+1) // cluster
							  begin
								    ge11_str_i [ist][icid][si] = ge11_str [ev][ist][icid][si];
								    ge11_prt_i [ist][icid][si] = ge11_prt [ev][ist][icid][si];
								    ge11_csz_i [ist][icid][si] = ge11_csz [ev][ist][icid][si];
								    ge11_vf_i  [ist][icid][si] = ge11_str [ev][ist][icid][si] != 8'hff;
                                     if (ge11_vf_i [ist][icid][si] == 1'b1)
                                     begin
                                        $fwrite(sim_out, "GEM_RAW: ev: %4d sch: %1d ly: %1d cls: %1h str: %h prt: %h\n",
                                                ev, ist, icid, si, ge11_str_i [ist][icid][si], ge11_prt_i [ist][icid][si]);
                                     end
						      end
						end
				    end



					ev = ev + 1;
					// count event as good if more than 2 stations, other than 3-4
					if (good_ev != 0 && good_ev != 1 && good_ev != 2 && good_ev != 4 && good_ev != 8 && 
						good_ev != 16 && good_ev != 24) 
					  good_ev_cnt = good_ev_cnt+1;
					if (good_ev == 24) st_cnt = 7; // 3-4 tracks marked as having 7 stations
					begin_time = $time;
				end
				
				//if (i == 210 || i == 220) lat_test = 1'b1;
				//else lat_test = 1'b0;
				
				// Run the Clock
                clki = 1'b0;
                #10
                clki = 1'b1;
                #10 
				

				// Read info from inside sp
				if (i > 0)
				begin

					iev = i;
					$fwrite(sim_out, "event: %d\n", iev);

					//$fwrite(sim_out, "ph: %d %d %d %d %d\n", 
					//		uut.ph[0][3][0], uut.ph[1][3][0], uut.ph[2][3][0], uut.ph[3][3][0], uut.ph[4][3][0]);
					/*
					for (si = 0; si < 7; si = si+1) // subsector
					begin
						for (j = 0; j < 3; j = j+1) // frame
						  begin
							 if (cppf_rxd[si][j] != 64'hffffffffffffffff)
							   $fwrite (sim_out, "CPPF: lnk: %d fr: %d d: %x\n", si, j, cppf_rxd[si][j]);
						end
					end
					*/
					/*				   
					for (si = 0; si < 4; si = si+1)
					for (ip = 0; ip < 6; ip = ip+1)
					begin
						for (j = 0; j < 9; j = j+1)
						begin
							for (k = 0; k < 2; k = k+1)
							  begin
								 if (uut.cpatd[si][ip][j][k] == 4'h0 && uut.vld[si][ip][j][k] == 1'h1) // RPC stub
								   begin
									  $fwrite (sim_out, "RPC: hi: %d st: %d ch: %d seg: %d ph: %d th: %d\n",
											   si, ip, j, k, uut.phd[si][ip][j][k], uut.thd[si][ip][j][k]);
								   end
								 if (uut.cpatd[si][ip][j][k] != 4'h0 && uut.vld[si][ip][j][k] == 1'h1) // ME stub
								   begin
									  $fwrite (sim_out, "ME : hi: %d st: %d ch: %d seg: %d ph: %d th: %d\n",
											   si, ip, j, k, uut.phd[si][ip][j][k], uut.thd[si][ip][j][k]);
								   end
							end
						end
					end
					*/

					// Print CSC Stubs
					for (ip = 0; ip < 6; ip = ip+1) // station
					begin
						for (j = 0; j < 9; j = j+1) // chamber
						begin
							for (k = 0; k < 2; k = k+1) // segment
							begin
								if (uut.vl[ip][j][k] != 0)
								begin
								
								    //$fwrite (sim_out, "STUB valid: st: %d ch: %d seg: %d\n", ip, j, k);
								
									if (ip <= 1 && j < 3) // ME11
								    begin
										$fwrite(sim_out, "CSC_STUB: st: %1d ch: %1d ph: %d  th: %d %d ph_zone: %d cpattern: %d\n", 
												ip, j, uut.ph[ip][j][k], uut.th11[ip][j][k*2], uut.th11[ip][j][k*2+1],uut.phzvl[ip][j], uut.cpatr[ip][j][k]);
										 ph_high_prec = uut.ph[ip][j][k];
									end
									else if (ip == 5 && j == 0) // ME11 neighbor
                                        $fwrite(sim_out, "CSC_STUB: st: %1d ch: %1d ph: %d  th: %d %d ph_zone: %d cpattern: %d\n", 
												ip, j, uut.ph[ip][j][k], uut.th11[2][0][k*2], uut.th11[2][0][k*2+1],uut.phzvl[ip][j][k], uut.cpatr[ip][j][k]);
									else
									begin
										$fwrite(sim_out, "CSC_STUB: st: %1d ch: %1d ph: %d  th: %d ph_zone: %d cpattern: %d\n", 
												ip, j, uut.ph[ip][j][k], uut.th[ip][j][k],uut.phzvl[ip][j][k], uut.cpatr[ip][j][k]);//uut.ph_hit[ip][j][k],uut.ph_zone[ip][j][k]);
										 ph_high_prec = uut.ph[ip][j][k];
									end
								end
							end
						end
					end // for (ip = 0; ip < 6; ip = ip+1)

					// Output GEM Stubs
					for (ip = 0; ip < 7; ip = ip+1) // schamber
					begin
						for (j = 0; j < 2; j = j+1) // layer
						begin
							for (k = 0; k < 8; k = k+1) // cluster
							begin
						
							    if (uut.ge11_vl[ip][j][k] != 0)
							    begin
								    $fwrite(sim_out, "GEM_STUB: sch: %1d ly: %1d cluster: %1d ph: %h th: %h\n",
								            ip, j, k, uut.ge11_ph[ip][j][k], uut.ge11_th[ip][j][k]);
	                            end
	                        end
	                    end
	                end

					// Output patterns w/ quality over 0
					for (iz = 0; iz < 4; iz = iz+1) // zone loop
					begin
						for (ir = 0; ir < 3; ir = ir+1) // sorted pattern number
						begin
							if (uut.ph_q[iz][ir] > 0)
								$fwrite(sim_out, "PATTERN BEST: zone: %1d best_index: %1d ph_num: %3d rank: %2h ly: %b%b%b str: %b%b%b\n", 
								iz, ir, uut.ph_num[iz][ir], uut.ph_q[iz][ir],
								uut.ph_q[iz][ir][4], uut.ph_q[iz][ir][2], uut.ph_q[iz][ir][0], 
								uut.ph_q[iz][ir][5], uut.ph_q[iz][ir][3], uut.ph_q[iz][ir][1]
								);
						end
					end // for (iz = 0; iz < 4; iz = iz+1)


					for (iz = 0; iz < 4; iz = iz+1) // zone loop
					begin
						for (ir = 0; ir < ph_raw_w; ir = ir+1) // key strip loop
						  begin
						      if (uut.phps.qcode_p[iz][ir] > 0)
							     $fwrite(sim_out, "PATTERN before ghosts: zone: %1d phi_num: %3d rank: %2h\n", iz, ir, uut.phps.qcode_p[iz][ir]);
						  end 
                    end 
                    
                    for (iz = 0; iz < 4; iz = iz+1) // zone loop
					begin    
						for (ir = 0; ir < ph_raw_w; ir = ir+1) // key strip loop
						  begin
						      if (uut.ph_rank[iz][ir] > 0)
							     $fwrite(sim_out, "PATTERN: zone: %1d phi_num: %3d rank: %2h\n", iz, ir, uut.ph_rank[iz][ir]);
						  end
					end

                    /*
                    // Standard Matching 
					for (iz = 0; iz < 4; iz = iz+1) // zone loop
					begin
						for (ip = 0; ip < 3; ip = ip+1) // best pattern number
						begin
							for (ist = 0; ist < 4; ist = ist + 1) // station
							begin
								if (uut.patt_ph_vi[iz][ip][ist] > 0)
								begin

										$fwrite(sim_out, "match seg: z: %d pat: %d st: %d   vi: %b hi: %d ci: %d si: %d ph: %d  th  : %d %d\n", 
											   iz, ip, ist, uut.patt_ph_vi[iz][ip][ist], uut.patt_ph_hi[iz][ip][ist], uut.patt_ph_ci[iz][ip][ist], 
												uut.patt_ph_si[iz][ip][ist], uut.ph_match[iz][ip][ist],
											    uut.th_match[iz][ip][ist][0], uut.th_match[iz][ip][ist][1]);
										
								end
							end // for (ist = 0; ist < 4; ist = ist + 1)
						end
					end // for (iz = 0; iz < 4; iz = iz+1)
                    */
                
                    
                    /*
                    // Pipelined Matching
					for (iz = 0; iz < 4; iz = iz+1) // zone loop
					begin
						for (ip = 0; ip < 3; ip = ip+1) // best pattern number
						begin
							for (ist = 0; ist < 4; ist = ist + 1) // station
							begin
								if (uut.ser_phmatch_and_deltas.sim_vi[ip][iz][ist] > 0)
								begin

										$fwrite(sim_out, "match seg: z: %d pat: %d st: %d   vi: %b hi: %d ci: %d si: %d ph: %d  th  : %d %d\n", 
											   iz, ip, ist, uut.ser_phmatch_and_deltas.sim_vi[ip][iz][ist], uut.ser_phmatch_and_deltas.sim_hi[ip][iz][ist], uut.ser_phmatch_and_deltas.sim_ci[ip][iz][ist], 
												uut.ser_phmatch_and_deltas.sim_si[ip][iz][ist], uut.ser_phmatch_and_deltas.sim_ph_match[ip][iz][ist],
											    uut.ser_phmatch_and_deltas.sim_th_match[ip][iz][ist][0], uut.ser_phmatch_and_deltas.sim_th_match[ip][iz][ist][1]);
										
								end
							end // for (ist = 0; ist < 4; ist = ist + 1)
						end
					end // for (iz = 0; iz < 4; iz = iz+1)
                    */
                    
                    
                    /*
                    for (iz = 0; iz < 4; iz = iz+1)
	                begin
						for (ip = 0; ip < 3; ip = ip+1)
						begin
							if (uut.rank[iz][ip] != 0)
								$fwrite(sim_out, "Deltas z: %d pat: %d ph_deltas: %d %d %d %d %d %d th_deltas: %d %d %d %d %d %d\n",
										iz, ip,
										uut.delta_ph[iz][ip][0], uut.delta_ph[iz][ip][1], uut.delta_ph[iz][ip][2], uut.delta_ph[iz][ip][3], uut.delta_ph[iz][ip][4], uut.delta_ph[iz][ip][5],
										uut.delta_th[iz][ip][0], uut.delta_th[iz][ip][1], uut.delta_th[iz][ip][2], uut.delta_th[iz][ip][3], uut.delta_th[iz][ip][4], uut.delta_th[iz][ip][5]
								);
						end
					end
					*/
					

					
				   if (uut.twom.bt_rank_i[0] != 0)
					 $fwrite (sim_out, "2mu track: rank: %d\n", uut.twom.bt_rank_i[0]);
				   
					for (ip = 0; ip < 3; ip = ip+1)
					begin
					
					   if (uut.ptlut_addr_val[0])
						 begin
							// get PT from table
							pt_word = ptlut[uut.ptlut_addr[ip]/2]; // pt_word contains two pt values

							//pt_word_rev = `brev(pt_word); // bytes are reversed for some reason, unreverse
							//pt_value = uut.ptlut_addr[ip][0] == 1'b1 ? 
							//		   pt_word_rev[17:9] : pt_word_rev[8:0]; // low bit of address selects value
									   
					        // When using readmemh instead of fread()
					        pt_value = uut.ptlut_addr[ip][0] == 1'b1 ? pt_word[17:9] : pt_word[8:0];
					        $fwrite(sim_out, " track pt address: %b %h pt: %h\n", uut.ptlut_addr[ip], uut.ptlut_addr[ip], pt_value);
						
					        $fwrite(best_tracks, "ev: %d track pt address: %h pt_word: %h pt: %h\n", 
								   iev, uut.ptlut_addr[ip], pt_word_rev, pt_value);

						 end
				
					
					    if (hmt_out != 0)
					    begin
					       $fwrite (sim_out, "HMT trigger: %b\n", hmt_out);
					    end
					
						if (bt_rank[ip] != 0)
						begin

							$fwrite(sim_out, "ME ");
							if (bt_rank[ip][5]) $fwrite(sim_out, "-1");
							if (bt_rank[ip][3]) $fwrite(sim_out, "-2");
							if (bt_rank[ip][1]) $fwrite(sim_out, "-3");
							if (bt_rank[ip][0]) $fwrite(sim_out, "-4");
							$fwrite(sim_out, " track: %d  rank: %h ly: %d ph_deltas: %d %d %d %d %d %d th_deltas: %d %d %d %d %d %d phi: %d,  theta: %d cpat: %d %d %d %d\n\thcs:", 
									ip, bt_rank[ip],
									{bt_rank[ip][5], bt_rank[ip][3], bt_rank[ip][1], bt_rank[ip][0]},
									bt_delta_ph[ip][0], bt_delta_ph[ip][1], bt_delta_ph[ip][2], bt_delta_ph[ip][3], bt_delta_ph[ip][4], bt_delta_ph[ip][5], 
									bt_delta_th[ip][0], bt_delta_th[ip][1], bt_delta_th[ip][2], bt_delta_th[ip][3], bt_delta_th[ip][4], bt_delta_th[ip][5], 
									bt_phi[ip], bt_theta[ip], bt_cpattern[ip][0], bt_cpattern[ip][1], bt_cpattern[ip][2], bt_cpattern[ip][3]);

							$fwrite(best_tracks, "ev: %d ME ", iev);
						    if (bt_rank[ip][5]) $fwrite(best_tracks, "-1"); else $fwrite(best_tracks, "  ");
						    if (bt_rank[ip][3]) $fwrite(best_tracks, "-2"); else $fwrite(best_tracks, "  ");
						    if (bt_rank[ip][1]) $fwrite(best_tracks, "-3"); else $fwrite(best_tracks, "  ");
						    if (bt_rank[ip][0]) $fwrite(best_tracks, "-4"); else $fwrite(best_tracks, "  ");
							$fwrite(best_tracks, " track: %d  rank: %h ly: %d ph_deltas: %d %d %d %d %d %d th_deltas: %d %d %d %d %d %d phi: %d,  theta: %d cpat: %d hcs:", 
									ip, bt_rank[ip], 
									{bt_rank[ip][5], bt_rank[ip][3], bt_rank[ip][1], bt_rank[ip][0]},
									bt_delta_ph[ip][0], bt_delta_ph[ip][1], bt_delta_ph[ip][2], bt_delta_ph[ip][3], bt_delta_ph[ip][4], bt_delta_ph[ip][5], 
									bt_delta_th[ip][0], bt_delta_th[ip][1], bt_delta_th[ip][2], bt_delta_th[ip][3], bt_delta_th[ip][4], bt_delta_th[ip][5], 
									bt_phi[ip], bt_theta[ip], bt_cpattern[ip][0]);
						   
						   for (j = 0; j < 5; j = j+1)
						   begin
							  if (bt_vi[ip][j] == 1'b1) begin
								$fwrite(sim_out, " b%d-st%0d-ch%h-seg%d", bt_hi[ip][j], j, bt_ci[ip][j], bt_si[ip][j]);
								$fwrite(best_tracks, " %d-%h-%d", bt_hi[ip][j], bt_ci[ip][j], bt_si[ip][j]);
							  end
							  else begin
								$fwrite(sim_out, " ----");
								$fwrite(best_tracks, " ---");
							  end
                           end
                           $fwrite (sim_out, "\n");
                           $fwrite (best_tracks, "\n");

							//$fwrite(best_tracks_short, "ev: %d ", iev);
							$fwrite(best_tracks_short, " track: %d rank: %h phi: %d theta: %d\n", 
									ip, bt_rank[ip], bt_phi[ip], bt_theta[ip]);

						end
						
						if (nn_pt_v[ip] != 1'b0) begin
                          $fwrite (nn_out, "ev: %4d track: %1d NN_pt: %h NN_d0: %h NN_PT_V: %h NN_D0_V: %h \n", 
                                   iev, ip, nn_pt[ip], nn_d0[ip], nn_pt_v[ip], nn_d0_v[ip]);
                        end
					end // for (ip = 0; ip < 3; ip = ip+1)
				end
			end

			$fwrite (sim_out, "elapsed_time: %t\n", elapsed_time);
			$fclose (best_tracks);
			$fclose (best_tracks_short);
			$fclose (sim_out);
			$fclose (nn_out);
			
			
			$finish;

		end

    
    

endmodule


