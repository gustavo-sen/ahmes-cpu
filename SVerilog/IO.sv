// ===================== I/O Block =====================
module io_block (
    input  clk,
    input  reset_n,
    input  [7:0] addr,
    input  [7:0] write_data,
    input        write_en,
    input        read_en,
    output logic [7:0] read_data,
    input  [3:0] in_switches,
    output logic [3:0] out_leds
);

    logic [3:0] led_register;

    // Lógica de leitura
    always_comb begin
        read_data = 8'h00; // Default value when not reading or address not matched
        if (read_en) begin
            case (addr)
                8'h04: read_data = {4'b0000, in_switches}; // lê switches
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