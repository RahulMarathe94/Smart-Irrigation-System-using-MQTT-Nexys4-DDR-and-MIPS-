// mfp_ahb.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5
// AHB-lite bus module with 3 slaves: boot RAM, program RAM, and
// GPIO (memory-mapped I/O: switches and LEDs from the FPGA board).
// The module includes an address decoder and multiplexer (for 
// selecting which slave module produces HRDATA).

`include "mfp_ahb_const.vh"


module mfp_ahb
(
    input                       HCLK,
    input                       HRESETn,
    input      [ 31         :0] HADDR,        // ADDRESS WHERE THE VALUE IS WRITTEN
    input      [  2         :0] HBURST,
    input                       HMASTLOCK,
    input      [  3         :0] HPROT,
    input      [  2         :0] HSIZE,
    input      [  1         :0] HTRANS,
    input      [ 31         :0] HWDATA,       // ACTUAL DATA BEING WRITTEN
    input                       HWRITE,       // WRITE/READ BIT  1/0
    output     [ 31         :0] HRDATA,       // FROM RAM0 , RAM1, GPIO 
    output                      HREADY,
    output                      HRESP,
    input                       SI_Endian,

// memory-mapped I/O
    input      [`MFP_N_SW-1 :0] IO_Switch,     // Read from Switches
    input      [`MFP_N_PB-1 :0] IO_PB,         // To read from Pushbuttons
    output     [`MFP_N_LED-1:0] IO_LED,        // Drive the LEDS
    output     [7:           0] IO_7SEGEN_N,   // Enables for the Seven Segments
    output     [6:           0] IO_7SEG_N,     // To drive values to the Seven Segment Display
    output                      IO_7SEG_DP,    // To enable the Decimal Points in the Seven Segment Display
    output     [7:           0] IO_BotCtrl,    // 8 bit IO_BotCtl_in to the bot for Roatation and Speed of Wheels
    input      [31:          0] IO_BotInfo,    // 32 Bit BotInfo to the Nexys4DDR
    output                      IO_INT_ACK,    // 1 bit Acknowledge from the Nexys4DDR to the Handshake Module
    input                       IO_BotUpdt_Sync,// 1 bit IO_Bot_Updt_Sync to the Handshake Module
    input                       WIFI_RX        // Serial Data from WI-FI Module   
                  );


  wire [31:0] HRDATA2, HRDATA1, HRDATA0;
  wire [ 3:0] HSEL;                             // Changed value of HSEL to map the new Seven Segment Peripheral
  reg  [ 3:0] HSEL_d; 

  assign HREADY = 1;
  assign HRESP = 0;
	
  // Delay select signal to align for reading data
  always @(posedge HCLK)
  HSEL_d <= HSEL;

  // Module 0 - boot ram
  mfp_ahb_b_ram mfp_ahb_b_ram(HCLK, HRESETn, HADDR, HBURST, HMASTLOCK, HPROT, HSIZE,
                              HTRANS, HWDATA, HWRITE, HRDATA0, HSEL[0]);
  // Module 1 - program ram
  mfp_ahb_p_ram mfp_ahb_p_ram(HCLK, HRESETn, HADDR, HBURST, HMASTLOCK, HPROT, HSIZE,
                              HTRANS, HWDATA, HWRITE, HRDATA1, HSEL[1]);
  // Module 2 - GPIO 
  mfp_ahb_gpio mfp_ahb_gpio(HCLK, HRESETn, HADDR[5:2], HTRANS, HWDATA, HWRITE, HSEL[2], 
                            HRDATA2, IO_Switch, IO_PB, IO_LED, IO_BotCtrl,IO_BotInfo,IO_INT_ACK, IO_BotUpdt_Sync,WIFI_RX);    
  // Module 3- SevenSegment
  mfp_ahb_sevensegment mfp_ahb_sevensegment(HCLK, HRESETn, HADDR[5:2], HTRANS, HWDATA, 
                             HWRITE, HSEL[3], IO_7SEGEN_N, IO_7SEG_N, IO_7SEG_DP);
  
  ahb_decoder ahb_decoder(HADDR, HSEL);
  ahb_mux ahb_mux(HCLK, HSEL_d, HRDATA2, HRDATA1, HRDATA0, HRDATA);

endmodule


module ahb_decoder
(
    input  [31:0] HADDR,
    output [ 3:0] HSEL          
);

  // Decode based on most significant bits of the address
  assign HSEL[0] = (HADDR[28:22] == `H_RAM_RESET_ADDR_Match); // 128 KB RAM  at 0xbfc00000 (physical: 0x1fc00000)
  assign HSEL[1] = (HADDR[28]    == `H_RAM_ADDR_Match);       // 256 KB RAM at 0x80000000 (physical: 0x00000000)
  assign HSEL[2] = (HADDR[28:22] == `H_LED_ADDR_Match);       // GPIO at 0xbf800000 (physical: 0x1f800000)
  /////////////////////// ADDITION /////////////////////////////////
  assign HSEL[3] = (HADDR[28:22] == `H_7SEG_ADDR_Match);       
  ///////////////////////////////////////////////////////////////////
endmodule


module ahb_mux
(
    input             HCLK,
    input      [ 3:0] HSEL,            
    input      [31:0] HRDATA2, HRDATA1, HRDATA0,
    output reg [31:0] HRDATA
);

    always @(*)
      casez (HSEL)
	      4'b???1:    HRDATA = HRDATA0;       
	      4'b??10:    HRDATA = HRDATA1;
	      4'b?100:    HRDATA = HRDATA2;
	      default:   HRDATA = HRDATA1;
      endcase
endmodule

