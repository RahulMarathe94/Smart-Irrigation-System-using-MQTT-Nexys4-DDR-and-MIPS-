// mfp_uart_receiver.v
// Project Name: Wireless Crop Care
// Target Devices: Nexys4 DDR
// March 20th, 2018
// Rahul Marathe, Kiyasul Arif ,Abhishek Memane, SHubham Lokhande
// Group 5

`include "mfp_ahb_const.vh"

module mfp_uart_receiver
(
    input  clock,                                                            // System Clock of 50 Mhz
    input  reset_n,                                                          // Resetn -Active low 
    input  rx,                                                               // Serial Data from WI-FI Module
    output reg [7:0] byte_data,                                              // 8 bit value =(represents either 0 or 1)
    output           byte_ready                                              // When 8 bits data is transmitted byte_ready is asserted
);

    parameter  clock_frequency        = 50000000;                            // System Clock of 50 Mhz
 
    parameter  baud_rate              = 115200;                              // Baud Rate of the WI-FI Module is 115200
    localparam clock_cycles_in_symbol = clock_frequency / baud_rate;         // Ratio of the System CLock to the Baud Rate to indicate the Clocks ber bit the data is valid

   
    reg rx_sync1, rx_sync;                                                   // Synchronize rx input to clock

    always @(posedge clock or negedge reset_n)
    begin
        if (~reset_n)                                                        // If Reset is asserted 
        begin
            rx_sync1 <= 1;                                                   // Rx Sync 1 input set to 1 
            rx_sync  <= 1;                                                   // Rx Sync   input set to 1 
        end
        else                                                             
        begin
            rx_sync1 <= rx;                                                  // RX_Sync 1 is set to RX
            rx_sync  <= rx_sync1;                                            // RX_Sync is et ot RX_SYNC_1 
        end
    end

   

    reg prev_rx_sync;                                                         // Finding edge for start bit

    always @(posedge clock or negedge reset_n)
    begin
        if (~reset_n)
            prev_rx_sync <= 1;
        else
            prev_rx_sync <= rx_sync;
    end

    wire start_bit_edge = prev_rx_sync & ! rx_sync;

   

    reg [31:0] counter;                                                        // Counter to measure distance between symbols
    reg        load_counter;
    reg [31:0] load_counter_value;

    always @(posedge clock or negedge reset_n)                                 // Counter to hold a state for (System_Clock/Baud Rate) Cyles
    begin
        if (~reset_n)                                                          // If Reset is Asserted
            counter <= 0;                                                      // Counter is set to 0 
        else if (load_counter)
            counter <= load_counter_value;
        else if (counter != 0)
            counter <= counter - 1;
    end

    wire counter_done = counter == 1;

    

    reg       shift;                                                           // Shift register to accumulated data
    reg [7:0] shifted_1;                                                       // 8 bit reg to store value of shifted Serial bits
    assign    byte_ready = shifted_1 [0];                                      // If all 8 bits are shifted, byte ready is asserted high 

    always @(posedge clock or negedge reset_n)                                 // State Traversal 
    begin
        if (~reset_n)                                                          // If reset is asserted 
        begin
            shifted_1 <= 0;                                                    // Shift is set to 0 
        end
        else if (shift)                                                        // If Shift is assserted 
        begin
            if (shifted_1 == 0)
                shifted_1 <= 8'b10000000;
            else
                shifted_1 <= shifted_1 >> 1;                                   // Shift Input bit by bit and store it

            byte_data <= { rx, byte_data [7:1] };
        end
        else if (byte_ready)                                                  // If Byte Ready , all 8 bits are shifted in 
        begin
            shifted_1 <= 0;                                                   // Clear SHifted to 0 
        end
    end

    reg idle, idle_r;

    always @(*)                                                              // State Machine for determining State for the UART Timing 
    begin                                                                     
        idle  = idle_r;
        shift = 0;

        load_counter        = 0;
        load_counter_value  = 0;

        if (idle)                                                             // Idle State- Poll for Start Bit 
        begin
            if (start_bit_edge)                                               // If Start bit is 1 
            begin
                load_counter       = 1;                                       // Load Counter is set to 1 
                load_counter_value = clock_cycles_in_symbol * 3 / 2;          // Symbols divide by 2 to get the center of the symbol where value is stable
           
                idle = 0;
            end
        end
        else if (counter_done)                                                // if all 8 bits are transmitted assert counter done
        begin
            shift = 1;

            load_counter       = 1; 
            load_counter_value = clock_cycles_in_symbol;                    // Process the values 
        end
        else if (byte_ready)                                                // if Byte Ready, the conversion is done 
        begin
            idle = 1;                                                       // Return to idle 
        end
    end

    always @(posedge clock or negedge reset_n)                              // Reset Condition 
    begin
        if (~reset_n)                                                       // If Reset is asserted
            idle_r <= 1;                                                    // State is Idle 
        else
            idle_r <= idle;                                                 // Keep polling in Idle state 
    end

endmodule
