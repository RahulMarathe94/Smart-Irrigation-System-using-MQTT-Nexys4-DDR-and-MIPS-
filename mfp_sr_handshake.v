`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// mfp_sr_handshake.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5
// 
//////////////////////////////////////////////////////////////////////////////////
module mfp_sr_handshake(
    input IO_BotUpdt,                                   // 1 bit IO_Bot_Updt_Sync to the Handshake Module
    input clk1_in,                                      //  50 Mhz Clock from CLock Wizard
    output reg IO_BotUpdt_Sync,                         // 1 bit IO_Bot_Updt_Sync to the Handshake Module
    input IO_INT_ACK                                    // 1 bit Acknowledge from the Nexys4DDR to the Handshake 
    );
       
    always @(posedge clk1_in) begin        
    if(IO_INT_ACK == 1'b1) begin                        // If IO_INT_ACK is Asserted
    IO_BotUpdt_Sync <= 1'b0;                            // IO_BOT_UPDATE_SYNC is cleared
    end
    else if(IO_BotUpdt == 1'b1) begin                   // If IO_INT ACK is not asserted
    IO_BotUpdt_Sync <= 1'b1;                            // IO_BOT_UPDATE_SYNC is set High 
    end
    else
    begin
    IO_BotUpdt_Sync <= IO_BotUpdt_Sync;                 // Retain IO_BOT_UPDATE_SYNC
    end
    end
      
endmodule
