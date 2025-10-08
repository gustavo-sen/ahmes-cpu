`timescale 1ns / 1ps

module testbench;

    // Parameters for clock generation
    parameter CLK_PERIOD = 10; // 10 ns period for 100 MHz clock

    // Testbench signals
    logic        clk;
    logic        reset;
    logic [3:0]  in_switches; // Input switches
    logic [3:0]  out_leds;    // Output LEDs

    // Instantiate the top_level module
    top_level dut (
        .clk         (clk),
        .reset       (reset),
        .in_switches (in_switches),
        .out_leds    (out_leds)
    );

    // Clock generation
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2);
        clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // Test sequence
    initial begin
        // Initialize inputs
        reset       = 1'b1;
        in_switches = 4'b0000;

     


        repeat (2) @(posedge clk); // Hold reset for a few clock cycles
        reset = 1'b0;
        @(posedge clk); // Release reset

        // --- Program to be loaded into RAM (LDA + ADD + HLT) ---
        // Address 0x00: LDA 0x10  (Load Accumulator with data at address 0x10)
        // Address 0x01: 0x10      (Operand for LDA - address 0x10)
        // Address 0x02: ADD 0x11  (Add value from 0x11 to AC)
        // Address 0x03: 0x11      (Operand for ADD - address 0x11)
        // Address 0x04: HLT       (Halt)
        // Address 0x10: 0xAA      (Data to be loaded into AC)
        // Address 0x11: 0x05      (Data to be added to AC)

        // Pre-load RAM manually
        dut.ram_inst.mem[8'h00] = 8'h20; // LDA opcode
        dut.ram_inst.mem[8'h01] = 8'h10; // Operand: Address 0x10
        dut.ram_inst.mem[8'h02] = 8'h30; // ADD opcode
        dut.ram_inst.mem[8'h03] = 8'h11; // Operand: Address 0x11
        dut.ram_inst.mem[8'h04] = 8'hF0; // HLT opcode
        dut.ram_inst.mem[8'h10] = 8'hAA; // Data to be loaded (0xAA)
        dut.ram_inst.mem[8'h11] = 8'h05; // Data to be added (0x05)

        // Give enough time for the program to execute and HLT
        // LDA (4 cycles) + ADD (4 cycles) + HLT (4 cycles) = ~12 cycles minimum
        repeat (50) @(posedge clk); // Adjusted to be safe

        $display("--------------------------------------------------");
        $display("Simulation Finished");
        $display("Final PC: %h", dut.data_path_inst.pc_out);
        $display("Final AC: %h", dut.data_path_inst.ac_out);
        $display("Expected AC: %h", 8'hAA + 8'h05);
        $display("--------------------------------------------------");

        // Final verification for ADD operation
        if (dut.data_path_inst.ac_out == (8'hAA + 8'h05)) begin
            $display("TEST PASSED: ADD operation successful. Final AC: %h", dut.data_path_inst.ac_out);
        end else begin
            $display("TEST FAILED: ADD operation failed. Expected AC: %h, Got AC: %h.",
                     (8'hAA + 8'h05), dut.data_path_inst.ac_out);
        end

        $finish; // End simulation
    end

endmodule