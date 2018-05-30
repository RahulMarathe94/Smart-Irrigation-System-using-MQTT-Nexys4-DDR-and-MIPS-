
//////////////////////////////////////////////////////////////////////////////////
// Module Name: mfp_ahb_sevensegment
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5
// 
//////////////////////////////////////////////////////////////////////////////////

`include "mfp_ahb_const.vh"

module mfp_ahb_sevensegment(
   input                        HCLK,
   input                        HRESETn,
   input      [  3          :0] HADDR,
   input      [  1          :0] HTRANS,
   input      [ 31          :0] HWDATA,
   input                        HWRITE,
   input                         HSEL,
// output reg [ 31          :0] HRDATA,
     
   output    [7:         0]  IO_7SEGEN_N,             ///// To store Enables for the 7 Segment Display
   output    [6:         0]  IO_7SEG_N,               ///// To drive values onto the Seven Segment Displays
   output                    IO_7SEG_DP);             ///// To store Enable the Decimal Points 
   
   reg       [7:         0]   H_7SEGEN;               ///// Temp Register to store Enables for the & Segment Display
   reg       [7:         0]   H_7SEG_DP;              ///// Temp Register to store Enable the Decimal Points 
   reg       [31:        0]   H_7SEGHIGH, H_7SEGLOW;  ///// Temp Register to store drive values onto the Lower and Higher 32 bit Registers     
   wire we;                                           ///// Temp Register to store Write Enable Signal , High IF HSEL and HWRITE both are one
     
    assign we = (HSEL&&HWRITE);                   
   always @ (posedge HCLK or negedge HRESETn)
 begin
    if(~HRESETn)
    begin
         
            H_7SEGEN   <=8'hff;                         ///// High Value to reset the Enables
            H_7SEG_DP  <=8'hff;                         ///// High Value to reset the Decimal Points
            H_7SEGHIGH <=32'hffff;                      ///// High Value to reset the Upper 32 bits 
            H_7SEGLOW  <=32'hffff;                      ///// High Value to reset the Lower 32 bits
     end
    else if (we)
    case (HADDR)                                        ///// Check bits 5:2 of HADDR and map to the correct Register
     `H_7SEGEN_IONUM: H_7SEGEN    <= HWDATA[7:0];       ///// H_7SEGEN Registers to Hold value of the HWDATA     
     `H_7SEG_DP_IONUM : H_7SEG_DP   <= HWDATA[7:0];     ///// H_7SEG_DP Registers to Hold value of the HWDATA             
     `H_7SEGHIGH_IONUM: H_7SEGHIGH  <= HWDATA[31:0];    ///// H_7SEGHIGH Registers to Hold value of the HWDATA         
     `H_7SEGLOW_IONUM: H_7SEGLOW   <= HWDATA[31:0];     ///// H_7SEGLOW Registers to Hold value of the HWDATA   
    endcase
                                       
  end
   mfp_ahb_sevensegtimer mfp_ahb_sevensegtimer(.clk(HCLK), .resetn(HRESETn), .EN(H_7SEGEN), .DIGITS({H_7SEGHIGH,H_7SEGLOW}), .dp(H_7SEG_DP) , .DISPENOUT(IO_7SEGEN_N), .DISPOUT({IO_7SEG_DP,IO_7SEG_N}));  
  
endmodule
