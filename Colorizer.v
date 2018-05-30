`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Colorizer.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5
// 
//////////////////////////////////////////////////////////////////////////////////


module colorizer( input clock,                    // Clock 75 Mhz  
                  input reset,                    // Reset Active Low 
                  input video_on,                 // Video On bit from Dtg
                  input [1:0] world_pixel,        // 2 bit Pixel Input from World Map
                  input [1:0] icon,               // 2 bit Pixel Input from Icon
                  input [1:0] icon2,icon4,icon5,icon6,icon7,
                  output reg [3:0] red,           // 4 Bit Red Colour Ouput to VGA
                  output reg [3:0] green,         // 4 Bit Green Colour Ouput to VGA
                  output reg [3:0] blue           // 4 Bit Blue Colour Ouput to VGA                      
    );
    //////////////////////Parameters for Background//////////////////////////// 
    //////////////////////////// rrrrggggbbbb//////////////////////////////////   
    parameter background  =  12'b111111111111;    // White Background colour
    parameter blackline   =  12'b000000000000;    // Blackline
    parameter Obstruction =  12'b111100000000;    // Obstruction==Red
    parameter Reserved    =  12'b111100001111;    // Reserved Background colour
    
    parameter sprinkler   =  12'b000000001111;    // Blue for Sprinkler
    ////////////////////// MAP ///////////////////////////////////////////
    parameter Icon_colour1=  12'b000000000000;    // Black
    parameter Icon_colour2=  12'b110001100000;    // Brown
    parameter Icon_colour3=  12'b000011110000;    // Green colour
    parameter Icon_colour4=  12'b111111111111;    // White colour
//////////////////////////////////////////////////////////////////////////////////////////
always@(posedge clock)
begin
if(video_on) begin                               // Check if Video_on Bit is High
    if(icon==2'b00 && icon2==2'b00 && icon4==2'b00
    && icon5==2'b00 && icon6==2'b00 && icon7==2'b00) begin                        // Check if Bit from Icon is 00 I
    case(world_pixel)
    2'b00: {red,green,blue}<= Icon_colour4;        // Fill the Background Colour with White 
    2'b01: {red,green,blue}<= Icon_colour1;         // Fill the Line with Black
    2'b10: {red,green,blue}<= Icon_colour2;       // Any Obstruction  //Brown
    2'b11: {red,green,blue}<= Icon_colour3;          // For Future Additions // green
    endcase
    end
   else begin  
   if(icon||icon2||icon4||icon5||icon6||icon7==2'b01)
      {red,green,blue}<= blackline; 
   else if(icon||icon2||icon4||icon5||icon6||icon7==2'b10)
       {red,green,blue}<=Obstruction;
   else if(icon||icon2||icon4||icon5||icon6||icon7==2'b11)
        {red,green,blue}<=sprinkler;

     end  
     end  
 else
 {red,green,blue}<=12'b000000000000;            // As Video_on is zero turn the screen black
    
end
endmodule