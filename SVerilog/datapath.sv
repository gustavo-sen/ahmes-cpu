module datapath (
    // --- Control Inputs ---
    input  logic         clk,
    input  logic         reset,          // Synchronous active-high reset
    input  logic         pc_load_en,     // Enable loading PC from data_bus_in
    input  logic         pc_inc_en,      // Enable PC increment
    input  logic         ac_load_en,     // Enable loading Accumulator from ALU result
    input  logic         flags_load_en,  // Enable loading status flags from ALU
    input  logic [3:0]   alu_op,         // ALU operation select
    input  logic         alu_cin,        // Carry-in for ALU

    // --- I/O Control ---
    input  logic         io_write_en,
    input  logic         io_read_en,

    // --- Data Busses & External I/O ---
    input  logic [7:0]   data_bus_in,    // General purpose data input bus
    input  logic [7:0]   addr_bus_in,    // Address bus for I/O
    input  logic [3:0]   in_switches,    // Asynchronous input from switches

    // --- Data & Status Outputs ---
    output logic [7:0]   pc_out,         // Program Counter output
    output logic [7:0]   ac_out,         // Accumulator output
    output logic [7:0]   io_read_data,   // Data read from I/O
    output logic [3:0]   out_leds,       // Output to LEDs
    output logic         flag_n,         // Negative flag output
    output logic         flag_z,         // Zero flag output
    output logic         flag_c,         // Carry flag output
    output logic         flag_b,         // Borrow flag output
    output logic         flag_v          // Overflow flag output
);

    // =================================================================
    // Internal Registers
    // =================================================================
    logic [7:0] pc_reg;
    logic [7:0] ac_reg;
    logic [3:0] led_reg;
    logic [3:0] in_switches_sync_stage1;
    logic [3:0] in_switches_sync;

    // Flags as registers
    logic n_reg, z_reg, c_reg, b_reg, v_reg;

    // ALU wires
    logic [7:0] alu_result;
    logic       alu_n, alu_z, alu_c, alu_b, alu_v;

    // =================================================================
    // Sequential Logic
    // =================================================================
    always @(posedge clk) begin
        if (reset) begin
            pc_reg   <= 8'h00;
            ac_reg   <= 8'h00;
            n_reg    <= 1'b0;
            z_reg    <= 1'b0;
            c_reg    <= 1'b0;
            b_reg    <= 1'b0;
            v_reg    <= 1'b0;
            led_reg  <= 4'b0;
            in_switches_sync_stage1 <= 4'b0;
            in_switches_sync        <= 4'b0;
        end else begin
            // --- Program Counter ---
            if (pc_load_en)
                pc_reg <= data_bus_in;
            else if (pc_inc_en)
                pc_reg <= pc_reg + 8'd1;

            // --- Accumulator ---
            if (ac_load_en)
                ac_reg <= alu_result;

            // --- Flags ---
            if (flags_load_en) begin
                n_reg <= alu_n;
                z_reg <= alu_z;
                c_reg <= alu_c;
                b_reg <= alu_b;
                v_reg <= alu_v;
            end

            // --- I/O Write (LEDs) ---
            if (io_write_en && addr_bus_in == 8'h00) begin
                led_reg <= ac_reg[3:0];
            end

            // --- Switch Synchronizer ---
            in_switches_sync_stage1 <= in_switches;
            in_switches_sync        <= in_switches_sync_stage1;
        end
    end

    // =================================================================
    // ALU Combinational Logic
    // =================================================================
    always @(*) begin
        // Opcodes
        localparam ADIC = 4'b0001;
        localparam SUB  = 4'b0010; 
        localparam OU   = 4'b0011; 
        localparam E    = 4'b0100; 
        localparam NAO  = 4'b0101; 
        localparam XOU  = 4'b0110; 
        localparam DLE  = 4'b0111; 
        localparam DLD  = 4'b1000; 
        localparam DAE  = 4'b1001; 
        localparam DAD  = 4'b1010; 

        logic [8:0] temp9;

        // Default values
        alu_result = 8'h00;
        alu_n = 1'b0;
        alu_z = 1'b0;
        alu_c = 1'b0;
        alu_b = 1'b0;
        alu_v = 1'b0;

        case (alu_op)
            ADIC: begin
                temp9 = {1'b0, ac_reg} + {1'b0, data_bus_in} + {8'b0, alu_cin};
                alu_result = temp9[7:0];
                alu_c = temp9[8];
                alu_v = (ac_reg[7] == data_bus_in[7]) && (ac_reg[7] != alu_result[7]);
                alu_b = 1'b0;
            end

            SUB: begin
                temp9 = {1'b0, ac_reg} - {1'b0, data_bus_in};
                alu_result = temp9[7:0];
                alu_b = temp9[8];
                alu_c = ~temp9[8]; // carry = not borrow
                alu_v = (ac_reg[7] != data_bus_in[7]) && (ac_reg[7] != alu_result[7]);
            end

            OU:   alu_result = ac_reg | data_bus_in;
            E:    alu_result = ac_reg & data_bus_in;
            NAO:  alu_result = ~ac_reg;
            XOU:  alu_result = ac_reg ^ data_bus_in;

            DLE: begin 
                alu_c = ac_reg[7];
                alu_result = {ac_reg[6:0], alu_cin};
            end

            DAE: begin 
                alu_c = ac_reg[7];
                alu_result = {ac_reg[6:0], 1'b0};
            end

            DLD: begin 
                alu_c = ac_reg[0];
                alu_result = {alu_cin, ac_reg[7:1]};
            end

            DAD: begin 
                alu_c = ac_reg[0];
                alu_result = {1'b0, ac_reg[7:1]};
            end

            default: alu_result = 8'h00;
        endcase

        // Common flags
        alu_z = (alu_result == 8'b0);
        alu_n = alu_result[7];
    end

    // =================================================================
    // I/O Read Logic
    // =================================================================
    always @(*) begin
        io_read_data = 8'h00; 
        if (io_read_en) begin
            case (addr_bus_in)
                8'h04: io_read_data = {4'b0000, in_switches_sync};
                default: io_read_data = 8'h00;
            endcase
        end
    end

    // =================================================================
    // Outputs
    // =================================================================
    assign pc_out   = pc_reg;
    assign ac_out   = ac_reg;
    assign out_leds = led_reg;

    assign flag_n = n_reg;
    assign flag_z = z_reg;
    assign flag_c = c_reg;
    assign flag_b = b_reg;
    assign flag_v = v_reg;

endmodule
