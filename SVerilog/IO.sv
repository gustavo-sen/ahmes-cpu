// ===================== I/O Block =====================
module io_block (
    input  clk,
    input  reset_n,
    input  [7:0] addr,
    input  [7:0] write_data,
    input        write_en,
    input        read_en,
    output logic [7:0] read_data,
    input  [3:0] in_switches, // Asynchronous input
    output logic [3:0] out_leds
);

    logic [3:0] led_register;
    logic [3:0] in_switches_sync_stage1; // First stage of synchronizer
    logic [3:0] in_switches_sync;        // Synchronized switches output

    // Synchronizer for in_switches
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            in_switches_sync_stage1 <= 4'b0000;
            in_switches_sync        <= 4'b0000;
        end else begin
            in_switches_sync_stage1 <= in_switches;        // Capture raw input
            in_switches_sync        <= in_switches_sync_stage1; // Output synchronized version
        end
    end

    // Lógica de leitura
    always_comb begin
        read_data = 8'h00; // Default value when not reading or address not matched
        if (read_en) begin
            case (addr)
                8'h04: read_data = {4'b0000, in_switches_sync}; // lê switches (now synchronized)
                default: read_data = 8'h00; // Default for unmatched read addresses
            endcase
        end
    end

    // Lógica de escrita
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            led_register <= 4'b0000;
        else if (write_en) begin
            case (addr)
                8'h00: led_register <= write_data[3:0]; // escreve LEDs
                default: ; // Do nothing for undefined write addresses
            endcase
        end
    end

    assign out_leds = led_register;

endmodule