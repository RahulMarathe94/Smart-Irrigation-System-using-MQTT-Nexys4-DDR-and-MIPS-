`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Icon.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, Shubham Lokhande
// Group 5
//
// 
//////////////////////////////////////////////////////////////////////////////////


module icon( input clock,reset,sysclk,                   
             input [7:0]LocX,LocY,BotInfo,
             input [9:0] pixel_row,pixel_column,
             output reg [1:0] icon
    );
    
       wire [2:0] orientation;                                                                        // To store 3 bit value of Orientation
    assign orientation=  BotInfo[2:0];                                                                // The last 3 bits of the BotInfo Register contains Orientation. 
    
     reg [7:0] address_N ,address_E,address_NE,address_NW,address_S ,address_W,address_SW,address_SE; // Store Addresses from the ROM 
     wire[1:0] doutN,doutS,doutE, doutW,doutNE,doutNW,doutSE, doutSW;                                 // Store 2 bit Data from Block ROMS
    
   
    //////////////////////////////////////////////////////// Block ROM Instantiations /////////////////////////////////////////////////////
    blk_mem_gen_sprinkler1 sprinkler1(
      .clka(sysclk),    																			  // input wire clka
      .addra(address_N),  																			  // input wire [7 : 0] addra
      .douta(doutN)  																				  // output wire [1 : 0] douta
    );
                  
    blk_mem_gen_sprinkler2 sprinkler2 (
      .clka(sysclk),    																			  // input wire clka
      .addra(address_E),  																			  // input wire [7 : 0] addra
      .douta(doutE)                                                                                   // output wire [1 : 0] douta
    );   
   
    blk_mem_gen_sprinkler3 sprinkler3 (
         .clka(sysclk),    																			  // input wire clka
         .addra(address_NE),  																		  // input wire [7 : 0] addra
         .douta(doutNE)  																			  // output wire [1 : 0] douta
    );
                     
    blk_mem_gen_sprinkler4 sprinkler4 (
         .clka(sysclk),    																			  // input wire clka
         .addra(address_NW),  																		  // input wire [7 : 0] addra
         .douta(doutNW)  																			  // output wire [1 : 0] douta
    );  
      
          
    blk_mem_gen_sprinkler5 sprinkler5(
          .clka(sysclk),    																		  // input wire clka
          .addra(address_S),  																		  // input wire [7 : 0] addra
          .douta(doutS)  																			  // output wire [1 : 0] douta
    );
                      
    blk_mem_gen_sprinkler6 sprinkler6 (
          .clka(sysclk),    																		  // input wire clka
          .addra(address_W),  																		  // input wire [7 : 0] addra
          .douta(doutW)  																			  // output wire [1 : 0] douta
    );   
      
    blk_mem_gen_sprinkler7 sprinkler7 (
             .clka(sysclk),    																		  // input wire clka
             .addra(address_SW),  																	  // input wire [7 : 0] addra
             .douta(doutSW)  																		  // output wire [1 : 0] douta
    );
                         
    blk_mem_gen_sprinkler8 sprinkler8 (
             .clka(sysclk),    																		  // input wire clka
             .addra(address_SE),                                                                      // input wire [7 : 0] addra
             .douta(doutSE)                                                                           // output wire [1 : 0] douta
    );   
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge clock) begin
if (((LocY*6) == pixel_row) && ({LocX,3'b000} == pixel_column)) begin
      
 if(orientation == 3'b000) begin                 		                              				 // Bot facing North(0 deg Orientation)
                address_N <= 8'd0;
                icon <= doutN;
                end
            else if(orientation == 3'b100) begin                                      				 // Bot facing South(180 deg Orientation)
                        address_S <= 8'd0;
                        icon <= doutS;
                 end
             else if(orientation == 3'b010) begin                                    				 // Bot facing East (90 deg Orientation)
                         address_E <= 8'd0;
                         icon <= doutE;
                  end    
              else if(orientation == 3'b110) begin                                   				 // Bot facing West(270 deg Orientation)
                       address_W <= 8'd0;
                       icon <= doutW;
                end
                
              else if(orientation == 3'b001) begin                                  				 // Bot facing NE(45 deg Orientation)
                       address_NE <= 8'd0;
                       icon <= doutNE;
                       end   
               else if(orientation == 3'b101) begin                                 				 // Bot facing SW(225 deg Orientation)
                      address_SW <= 8'd0;
                      icon <= doutSW;
                      end 
                      
               else if(orientation == 3'b111) begin                                 				// Bot facing NW(315 deg Orientation)
                     address_NW <= 8'd0;
                     icon <= doutNW;
                     end  
               else if(orientation == 3'b011) begin                                 				// Bot facing SE(135 deg Orientation)
                        address_SE <= 8'd0;
                        icon <= doutSE;
                        end  
end
 else if ((pixel_row >= (LocY*6)) && (pixel_row <= (LocY*6) + 4'd15) && (pixel_column >= {LocX,3'b000}) && (pixel_column <= {LocX, 3'b000} + 4'd15))
 
           begin
               if(orientation == 3'b000) begin                                      				// Bot facing North(0 deg Orientation)
                       address_N <= address_N + 1;
                       icon <= doutN;
                       end
               else if(orientation == 3'b100) begin                                 				// Bot facing South(180 deg Orientation)
                       address_S <= address_S + 1;
                       icon <= doutS;
                       end
                else if(orientation == 3'b010) begin                                				// Bot facing East (90 deg Orientation)
                        address_E <= address_E + 1;
                        icon <= doutE;
                       end    
                 else if(orientation == 3'b110) begin                               				// Bot facing West(270 deg Orientation)
                          address_W <= address_W + 1;
                          icon <= doutW;
                          end
                 else if(orientation == 3'b001) begin                              					// Bot facing NE(45 deg Orientation)
                         address_NE <= address_NE + 1;
                         icon <= doutNE;
                         end   
                 else if(orientation == 3'b101) begin                             					// Bot facing SW(225 deg Orientation)
                        address_SW <= address_SW + 1;
                        icon <= doutSW;
                        end 
                        
                 else if(orientation == 3'b111) begin                            					// Bot facing NW(315 deg Orientation)
                       address_NW <= address_NW + 1;
                       icon <= doutNW;
                       end  
                 else if(orientation == 3'b011) begin                           					// Bot facing SE(135 deg Orientation)
                          address_SE <= address_SE + 1;
                          icon <= doutSE;
                          end
               end
       else 
           begin                                                              					   // Retain the Address if the Bot Location Conditions are not satisfied
              address_N <= address_N;                                  
              address_E <= address_E;
              address_NW <= address_NW;
              address_NE <= address_NE;
              address_S <= address_S;                                  
              address_W <= address_W;
              address_SE <= address_SE;
              address_SW <= address_SW;
              icon <= 2'b00;
           end
       end              
endmodule
