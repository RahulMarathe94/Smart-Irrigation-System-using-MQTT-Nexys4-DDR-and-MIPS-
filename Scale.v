`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Scale.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, Shubham Lokhande
// Group 5
// 
//////////////////////////////////////////////////////////////////////////////////


module scale(input clock,                                 // Clock Input 75 Mhz
             input reset,                                 // CPU RESET ACTIVE LOW
             input [11:0] pixel_row,pixel_col,            // 12 Bit Row and Column Pixels from DTG
             output reg [13:0] vid_addr                   // 14 bit Ouput is {Row[6:0],Col[6:0]}
    );
    
             reg [6:0] pixel_column_d;                    // Reg to hold Ouptut Row Value
             reg [6:0] pixel_row_d;                       // Reg to hold Ouptut Column Value
             
             always@(posedge clock)                       // Scale at every Posedge of Clock
             begin
             pixel_column_d <= pixel_col/8;               // Divide Column Address by 8 to Scale to 128(1024)
             pixel_row_d    <= pixel_row/6;               // Divide Row Address by 6 to Scale to 128(768)
             vid_addr <= {pixel_row_d,pixel_column_d};
             end
endmodule
