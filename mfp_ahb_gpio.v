// mfp_ahb_gpio.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5
// General-purpose I/O module for Altera's DE2-115 and 
// Digilent's (Xilinx) Nexys4-DDR board


`include "mfp_ahb_const.vh"

module mfp_ahb_gpio(
    input                        HCLK,
    input                        HRESETn,
    input      [  3          :0] HADDR,
    input      [  1          :0] HTRANS,
    input      [ 31          :0] HWDATA,
    input                        HWRITE,
    input                        HSEL,
    output reg [ 31          :0] HRDATA,

// memory-mapped I/O ////////////////////////////
    input      [`MFP_N_SW-1  :0] IO_Switch,            // Read from Switches
    input      [`MFP_N_PB-1  :0] IO_PB,                // To read from Pushbuttons 
    output reg [`MFP_N_LED-1 :0] IO_LED,               // Drive the LEDS
    output reg [7:         0]    IO_BotCtrl,           // 8 bit IO_BotCtl_in to the bot for Roatation and Speed of Wheels
    input      [31:        0]    IO_BotInfo,           // 32 Bit BotInfo to the Nexys4DDR
    output reg                   IO_INT_ACK,           // 1 bit Acknowledge from the Nexys4DDR to the Handshake Module
    input                        IO_BotUpdt_Sync,      // 1 bit IO_Bot_Updt_Sync to the Handshake Module
    input                        WIFI_RX               // Serial Data from WI-FI Module               
    
);

  reg  [3:0]  HADDR_d;
  reg         HWRITE_d;
  reg         HSEL_d;
  reg  [1:0]  HTRANS_d;
  wire        we;            // write enable
  
  wire [5:0] pbtn_db;        // To hold the debounced value of Push Button
  wire [15:0] switch_db;     // To hold the debounced value of the Switches
  wire		  byte_ready;    // To hold Value of Byte Ready when the 8 bits are transmitted 
  wire  [7:0] byte_data;     // Holds the 8 bit byte data from the WI-FI Module(Either 0 or 1)
  ////////////////////////////////////////////
  reg [31:0] temp;
 reg [31:0]IO_TEMP;
 
  // TO DEBOUNCE THE VALUES OF THE SWITCHES AND THE PUSHBUTTON
debounce debounce(.pbtn_db(pbtn_db), .swtch_db(switch_db),.pbtn_in(IO_PB), .switch_in(IO_Switch), .clk(HCLK));
  // delay HADDR, HWRITE, HSEL, and HTRANS to align with HWDATA for writing
  always @ (posedge HCLK) 
  begin
    HADDR_d  <= HADDR;
	HWRITE_d <= HWRITE;
	HSEL_d   <= HSEL;
	HTRANS_d <= HTRANS;
  end
  
  mfp_uart_receiver1 esp_receiver
 (.clock(HCLK), .reset_n(HRESETn), .rx(WIFI_RX), .byte_data(byte_data), .byte_ready(byte_ready)); // UART Receiver Module for parsing data from WI-FI Module
 

  // overall write enable signal
  assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;                              // Assert Write Enabe depending on values of HSelect and HWrite
    
    always @(posedge HCLK or negedge HRESETn)                                              // Writing to the AHB Bus
       if (~HRESETn) begin                                                                 // If Reset is Asserted
         IO_LED <= `MFP_N_LED'b0;                                                          // Clear data in the memory mapped address of LEDS
         IO_BotCtrl <= `MFP_N_BOTCTRL'b0;                                                  // Clear data in the memory mapped address of IO_BOTCTRL
         IO_INT_ACK <= `MFP_N_INTACK'b0;                                                   // Clear data in the memory mapped address of IO_INT_ACK
       end else if (we)                                                                    // Else if Write Enable is Asserted
         case (HADDR_d)
           `H_LED_IONUM: IO_LED <= HWDATA[`MFP_N_LED-1:0];                                 // Writing to the memory mapped address of LEDS
           `H_PORT_BOTCTRL: IO_BotCtrl <= HWDATA[`MFP_N_BOTCTRL-1:0];                      // Writing to the memory mapped address of IO_BOTCTRL
           `H_PORT_INTACK: IO_INT_ACK <= HWDATA[`MFP_N_INTACK-1:0];                        // Writing to the memory mapped address of IO_INT_ACK
           ////////////////////////////////////////////////////////////
           
         endcase
    
	always @(posedge HCLK or negedge HRESETn)                                             // Reading from the AHB Bus
       if (~HRESETn)                                                                      // If Reset i Asserted
         HRDATA <= 32'h0;                                                                 // Clear the data on the HRDATA bus
       else                                                                               // Else 
	     case (HADDR)
           `H_PMOD_IONUM: HRDATA <= { {32 - `MFP_N_UART {1'b0}}, byte_data };             // Bus reads data from Memory Mapped Address of PMOD
           `H_PB_IONUM: HRDATA <= { {32 - `MFP_N_PB {1'b0}}, pbtn_db };                   // Bus reads data from Memory Mapped Address of Pushbuttons
           `H_PORT_BOTINFO:  HRDATA <= { {32 - `MFP_N_BOTINFO {1'b0}}, IO_BotInfo };      // Bus reads data from Memory Mapped Address of Port_BotInfo from Rojobot   
           `H_PORT_BOTUPDT:  HRDATA <= { {31 {1'b0}}, IO_BotUpdt_Sync  };                 // Bus reads data from Memory Mapped Address of Port_BotUpdt from Rojobot 
                                                                             
                       default:    HRDATA <= 32'b0;
         endcase
		 
endmodule

