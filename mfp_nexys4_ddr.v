// mfp_nexys4_ddr.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5
// Outputs:
// 16 LEDs (IO_LED) 
// Seven Segement Display and Seven Segment Decimal Point
// Inputs:
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
// UART Data from Wifi Module on Connector JC 
//////////////////////////////////////////////////////////////////

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                        input                      CLK100MHZ,
                        input                      CPU_RESETN,
                        input                      BTNU, BTND, BTNL, BTNC, BTNR, 
                        input   [`MFP_N_SW-1 :0]   SW,
                        output  [`MFP_N_LED-1:0]   LED,
                        output  [7           :0]   AN,                     // Enables for the 7 Segment 
                        output                     DP,                     // Enables for the Decimal Points
                        output                     CA,CB,CC,CD,CE,CF,CG,   // Common Cathode Segments for the Seven Segments 
                        inout   [8          :1]    JB,
                        input                      UART_TXD_IN,            
                        output  [3          :0]   VGA_R,                     // VGA Red Colour Four Bits
                        output  [3          :0]   VGA_G,                     // VGA Green Colour Four Bits        
                        output  [3          :0]   VGA_B,                     // VGA Blue Colour Four Bits
                        output                    VGA_HS,                    // High Sync Pulse for VGA
                        output                    VGA_VS,                    // Low Sync Pulse for VGA       
                        input                     WIFI_RX                    // Data from WI-FI Module
                        );

  // Press btnCpuReset to reset the processor.    
  wire clk1_out, clk2_out; 
  wire tck_in, tck;
  wire [7:0] byte_data1;
  // wires for world_map and Bot31
  wire [1  : 0] worldmap_data;                                               // 2 Bit Wire for Data from World Map and Bot
  wire [13 : 0] worldmap_address;                                            // 8 Bit Wire for Address from World Map and Bot
  //////////////////////////////
                                      
  //////////////////////////////
  wire IO_BotUpdt_Sync;                                                      // Interconnect between the Handshake Flip Flop and Mfp_sys                                                      
  wire IO_INT_ACK;                                                           // 1 bit Acknowledge Signal between Handshake Flip FLop and Mfp_sys
  wire IO_BotUpdt;                                                           // 1 bit Bot Update from the Rojobot to the Handshake Flip Flop   
  wire [31:0] IO_BotInfo;                                                    // IO_BotInfo={LocX,LocY,Sensor_reg,BotInfo_reg}   
  wire [7:0] IO_BotCtrl;                                                     // IO_BotCtrl is a 1 bit register which has the Motor Control and Motor turn Bits
  /////////////////////////////
  wire [5:0] pbtn_db;                                                        //  6 Pushbuttons on the Board{LEFT,RIGHT,UP,DOWN,CENTER,CPU_RESETN}
  wire [15:0] switch_db;                                                     // Controls the 16 Slide Switches on the Board
  /////////////////////////////
  wire [7:0] LocX_reg, LocY_reg, Sensors_reg, BotInfo_reg;                   // 8 bit Interconnects for sending the signals from the Rojobot to the Mfp_sys
  wire [31:0] BotInfo;                                                       // BotInfo={LocX,LocY,Sensor_reg,BotInfo_reg}        

  ///////////////////////////HDL_2///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  /////for the dtg module//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  wire  [11:0] pixel_row,pixel_col;                                          // 12 Bit Pixel Values for Row and Column from dtg
  wire  video_on;                                                            // Video_on from DTG Module to switch on the display
  
  //////////////for thr scale module ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
  wire  [13:0] vid_addr;                                                     // Video Address from SCale is {[6:0] Pixel_row,[6:0] Pixel_col]}
  
  ///////////////for the colorizer module///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  wire [1:0] world_pixel;                                                         // from world_map 
  wire [1:0] icon_wire, icon_wire2,icon_wire4,icon_wire5,icon_wire6,icon_wire7;   // from various Icon modules c
  
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  wire [7:0] LocX2;                                                               // Wire to hold Offset from Center Pixel
  wire [7:0] LocX3;																  // Wire to hold Offset from Center Pixel
  wire [7:0] LocY2;																  // Wire to hold Offset from Center Pixel
  wire [7:0] LocY3;																  // Wire to hold Offset from Center Pixel
  
   assign LocX2 = BotInfo[31:24] + 8'b00101101;                                   // Offset to the Right of central pixel 
   assign LocX3 = BotInfo[31:24] - 8'b00101100;                                   // Offset to the left of central pixel 
   assign LocY2 = BotInfo[23:16] + 8'b00011011;                                   // Offset for calculating y direction(Positive Axis)
   assign LocY3 = BotInfo[23:16] - 8'b00011010;                                   // Offset for calculating y direction(Negative Axis)
  
  // Two clocks - Clk1_out is 50 Mhz for the Nexys4 DDR and 75Mhz for the VGA Controller/////////////////////////////////////////////////////////////////   
  clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk1_out), .clk_out2(clk2_out)); 
   
  
  debounce debounce2(.pbtn_db(pbtn_db), .swtch_db(switch_db),.pbtn_in({CPU_RESETN,BTNC, BTNL, BTNU, BTNR, BTND}), .switch_in(SW), .clk(clk1_out));
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));

  mfp_sys mfp_sys(
			        .SI_Reset_N(CPU_RESETN),
                    .SI_ClkIn(clk1_out),
                    .HADDR(),
                    .HRDATA(),
                    .HWDATA(),
                    .HWRITE(),
					.HSIZE(),
                    .EJ_TRST_N_probe(JB[7]),
                    .EJ_TDI(JB[2]),
                    .EJ_TDO(JB[3]),
                    .EJ_TMS(JB[1]),
                    .EJ_TCK(tck),
                    .SI_ColdReset_N(JB[8]),
                    .EJ_DINT(1'b0),
                    .IO_Switch(SW),
                    .IO_PB({CPU_RESETN,BTNC, BTNL, BTNU, BTNR, BTND}),           // Reset,UDLCR
                    .IO_LED(LED),
                    .IO_7SEGEN_N(AN),                                            // The Enables
                    .IO_7SEG_N({CA,CB,CC,CD,CE,CF,CG}),                          // The 7 Common Cathodes
                    .IO_7SEG_DP(DP),                                             // The Enable for Decimal Points
                    .UART_RX(UART_TXD_IN),
                    .IO_BotInfo             (   BotInfo                 ),       // 32 Bit BotInfo to the Nexys4DDR
                    .IO_BotCtrl             (   IO_BotCtrl              ),       // 8 bit IO_BotCtl_in to the bot for Roatation and Speed of Wheels     
                    .IO_INT_ACK             (   IO_INT_ACK              ),       // 1 bit Acknowledge from the Nexys4DDR to the Handshake Module
                    .IO_BotUpdt_Sync        (   IO_BotUpdt_Sync         ),       // 1 bit IO_Bot_Updt_Sync to the Handshake Module
                    .WIFI_RX                (   WIFI_RX                 )        // Serial Data from Wi-fi Module
                    );
   
   //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
   rojobot31_1 rojobot31_1 (
                         .MotCtl_in(IO_BotCtrl),                                // input wire [7 : 0] MotCtl_in
                         .LocX_reg(BotInfo[31:24]),                             // output wire [7 : 0] LocX_reg
                         .LocY_reg(BotInfo[23:16]),                             // output wire [7 : 0] LocY_reg
                         .Sensors_reg(BotInfo[15:8]),                           // output wire [7 : 0] Sensors_reg
                         .BotInfo_reg(BotInfo[7:0]),                            // output wire [7 : 0] BotInfo_reg
                         .worldmap_addr(worldmap_address),                      // output wire [13 : 0] worldmap_addr
                         .worldmap_data(worldmap_data),                         // input wire [1 : 0] worldmap_data
                         .clk_in(clk2_out),                                     // input wire clk_in
                         .reset(~CPU_RESETN),                                   // input wire reset
                         .upd_sysregs(IO_BotUpdt),                              // output wire upd_sysregs
                         .Bot_Config_reg(switch_db[7:0])                        // input wire [7 : 0] Bot_Config_reg // TODO : MAKE SURE PART SELECT WORKS
   );
  
   //------------------------------------------------ World Map ----------------------------------------------------------/////
   world_map world_map (                                                        // Instantiation of the World Map Module 
                        clk2_out,                                               // 75 Mhz Clock for the World Map
                        worldmap_address,                                       // 14 bit Address from the World Map to the bot
                        worldmap_data,                                          // 2 bit data to the Bot
                        clk2_out,                                               // 75 MHz Clock for the  World Map
                        vid_addr,                                               // Video_Address[13:0]={[6:0]row, [6:0] col}
                        world_pixel                                             // 2 Bit Ouptut from World Map
   );
   //----------------------------------------------- World Map --------------------------------------------------------//
  
  
   //---------------------------------------- Handshake Flip-Flop ------------------------------------------------------ // 
  mfp_sr_handshake mfp_sr_handshake (
  
                        .IO_BotUpdt(IO_BotUpdt),                                 // IO_BotUpdate from the Bot
                        .clk1_in(clk1_out),                                      // 50 Mhz Clock for the Handshake Flip Flop Module
                        .IO_BotUpdt_Sync(IO_BotUpdt_Sync),                       // Sync bit to the Nexys4DDr
                        .IO_INT_ACK(IO_INT_ACK)                                  // Acknowledge bit from the Nexys4DDR
 
  ); 

  // ---------------------------------------- Handshake Filp-Flop---------------------------------------------------------- //
   

   
   //----------------------------------------- Display timing Generator-----------//////////////////////////////////////////////////
   dtg dtg(	.clock(clk2_out),.rst(~CPU_RESETN),.horiz_sync(VGA_HS),.vert_sync(VGA_VS),.video_on(video_on)
   ,.pixel_row(pixel_row), .pixel_column(pixel_col));
   //--------------------------------------- Display timing Generator-----------//////////////////////////////////////////////////
   
   //----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
   icon icon(.clock(clk2_out),.reset(CPU_RESETN),.sysclk(clk1_out),.LocX(BotInfo[31:24]),.LocY(BotInfo[23:16])
   ,.BotInfo(BotInfo[7:0]),.pixel_row(pixel_row[9:0]),.pixel_column(pixel_col[9:0]),.icon(icon_wire));  
   //-----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
   //-----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
        icon icon4(.clock(clk2_out),.reset(CPU_RESETN),.sysclk(clk1_out),.LocX(BotInfo[31:24]),.LocY(LocY2)
        ,.BotInfo(BotInfo[7:0]),.pixel_row(pixel_row[9:0]),.pixel_column(pixel_col[9:0]),.icon(icon_wire4));  
   //-----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
    
   //----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
          icon icon5(.clock(clk2_out),.reset(CPU_RESETN),.sysclk(clk1_out),.LocX(BotInfo[31:24]),.LocY(LocY3)
          ,.BotInfo(BotInfo[7:0]),.pixel_row(pixel_row[9:0]),.pixel_column(pixel_col[9:0]),.icon(icon_wire5));  
            //--------------------------------Icon Module-----------------------////////////////////////////////////////////////////
          
   //----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
      icon icon2(.clock(clk2_out),.reset(CPU_RESETN),.sysclk(clk1_out),.LocX(LocX2),.LocY(BotInfo[23:16])
      ,.BotInfo(BotInfo[7:0]),.pixel_row(pixel_row[9:0]),.pixel_column(pixel_col[9:0]),.icon(icon_wire2));  
   //------------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
   //-----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
          icon icon6(.clock(clk2_out),.reset(CPU_RESETN),.sysclk(clk1_out),.LocX(LocX2),.LocY(LocY2)
          ,.BotInfo(BotInfo[7:0]),.pixel_row(pixel_row[9:0]),.pixel_column(pixel_col[9:0]),.icon(icon_wire6));  
   //-----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
      
   //----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
          icon icon7(.clock(clk2_out),.reset(CPU_RESETN),.sysclk(clk1_out),.LocX(LocX2),.LocY(LocY3)
        ,.BotInfo(BotInfo[7:0]),.pixel_row(pixel_row[9:0]),.pixel_column(pixel_col[9:0]),.icon(icon_wire7));  
   //----------------------------------------Icon Module-----------------------////////////////////////////////////////////////////
    
	
   //-------------------------------------Colorizer Module-------------------////////////////////////////////////////////////////
    colorizer colorizer(.clock(clk2_out),.reset(CPU_RESETN),.video_on(video_on)
    ,.world_pixel(world_pixel),.icon(icon_wire),.icon2(icon_wire2),.icon4(icon_wire4),.icon5(icon_wire5),.icon6(icon_wire6),.icon7(icon_wire7),
    .red(VGA_R),.green(VGA_G),.blue(VGA_B));
     //-----------------------------------Colorizer Module-------------------////////////////////////////////////////////////////   
    
  
   //-------------------------------------Scale Module------------------////////////////////////////////////////////////////////
   scale scale(.clock(clk2_out),.reset(CPU_RESETN),.pixel_row(pixel_row)
   ,.pixel_col(pixel_col),.vid_addr(vid_addr));    
   //--------------------------------------Scale Module------------------////////////////////////////////////////////////////////
     
endmodule
