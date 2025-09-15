`timescale 1ns/1ps

module tb_io_block;

    // Testbench signals
    logic clk;
    logic reset_n;
    logic [7:0] addr;
    logic [7:0] write_data;
    logic       write_en;
    logic       read_en;
    logic [7:0] read_data;
    logic [3:0] in_switches;
    logic [3:0] out_leds;

    // Instantiate the DUT
    io_block dut (
        .clk         (clk),
        .reset_n     (reset_n),
        .addr        (addr),
        .write_data  (write_data),
        .write_en    (write_en),
        .read_en     (read_en),
        .read_data   (read_data),
        .in_switches (in_switches),
        .out_leds    (out_leds)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        // Initialize signals
        reset_n = 0;
        addr = 8'h00;
        write_data = 8'h00;
        write_en = 0;
        read_en = 0;
        in_switches = 4'b1010; // Example switch state

        // Apply reset
        #12;
        reset_n = 1;
        #10;

        // Test writing LEDs
        addr = 8'h00;      // LED register address
        write_data = 8'b1101; 
        write_en = 1;
        #10;
        write_en = 0;

        // Check LED output
        $display("Time %0t: out_leds = %b (expected 1101)", $time, out_leds);

        // Test reading switches
        addr = 8'h04;      // Switch register address
        read_en = 1;
        #10;
        read_en = 0;

        $display("Time %0t: read_data = %b (expected 1010)", $time, read_data[3:0]);

        // Test writing another value to LEDs
        addr = 8'h00;
        write_data = 8'b0011;
        write_en = 1;
        #10;
        write_en = 0;

        $display("Time %0t: out_leds = %b (expected 0011)", $time, out_leds);

        // End simulation
        #20;
        $finish;
    end

endmodule
