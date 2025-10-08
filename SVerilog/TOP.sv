module top_level (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  in_switches,    // Physical switches input
    output logic [3:0]  out_leds        // Physical LEDs output
);

    // --- Control Unit Signals ---
    logic        uc_pc_load_en;
    logic        uc_pc_inc_en;
    logic        uc_ac_load_en;
    logic        uc_flags_reset;
    logic [3:0]  uc_alu_op;
    logic        uc_alu_cin;
    logic        uc_mem_write_en;
    logic        uc_mem_read_en;
    logic [7:0]  uc_mem_addr_bus_dp;    // Address bus driven by UC for Datapath (Memory/IO)
    logic [7:0]  uc_data_bus_to_dp;     // Data from UC to Datapath's data_bus_in
    logic        uc_sel_mem_data;       // NEW: selects memory/peripheral input for AC

    // --- Datapath Outputs to UC ---
    logic [7:0]  dp_pc_out;
    logic [7:0]  dp_ac_out;
    logic [7:0]  dp_mem_read_data;      // Data read by datapath (from memory or IO mux)
    logic        dp_flag_n;
    logic        dp_flag_z;
    logic        dp_flag_c;
    logic        dp_flag_b;
    logic        dp_flag_v;
    logic        uc_error;

    // --- Memory Interface Signals ---
    logic [7:0]  mem_data_read_out;   // Data read from the RAM
    logic [7:0]  mem_data_write_in;   // Data written to the RAM
    logic        mem_write_enable;    // Write enable for RAM
    logic        mem_read_enable;     // Read enable for RAM
    logic [7:0]  mem_address;         // Address for RAM access

    // --- Signals for instruction and operand fetching from RAM ---
    logic [7:0]  instr_from_mem;        // Instruction fetched from RAM
    logic [7:0]  data_operand_from_mem; // Operand/data fetched from RAM

    // Connect memory control signals from UC to RAM
    assign mem_address       = uc_mem_addr_bus_dp;
    assign mem_write_enable  = uc_mem_write_en;
    assign mem_read_enable   = uc_mem_read_en;
    assign mem_data_write_in = uc_data_bus_to_dp;

    // Instruction and data operand come from RAM's data_out
    assign instr_from_mem        = mem_data_read_out;
    assign data_operand_from_mem = mem_data_read_out;

    // Instantiate the Control Unit
    UC control_unit (
        .clk                 (clk),
        .reset               (reset),
        .data_bus_from_mem   (data_operand_from_mem), // Operand from RAM
        .instr_bus           (instr_from_mem),        // Instruction from RAM

        .pc_load_en          (uc_pc_load_en),
        .pc_inc_en           (uc_pc_inc_en),
        .ac_load_en          (uc_ac_load_en),
        .flags_reset         (uc_flags_reset),
        .alu_op              (uc_alu_op),
        .alu_cin             (uc_alu_cin),
        .mem_write_en        (uc_mem_write_en),
        .mem_read_en         (uc_mem_read_en),
        .mem_addr_bus_dp     (uc_mem_addr_bus_dp),
        .data_bus_to_dp      (uc_data_bus_to_dp),
        .sel_mem_data        (uc_sel_mem_data),       // NEW connection

        .pc_out_dp           (dp_pc_out),
        .ac_out_dp           (dp_ac_out),
        .mem_read_data_dp    (dp_mem_read_data),      // Data from datapath (RAM or IO)
        .flag_n_dp           (dp_flag_n),
        .flag_z_dp           (dp_flag_z),
        .flag_c_dp           (dp_flag_c),
        .flag_b_dp           (dp_flag_b),
        .flag_v_dp           (dp_flag_v),

        .ERROR               (uc_error)
    );

    // Instantiate the Datapath
    datapath data_path_inst (
        .clk                 (clk),
        .reset               (reset),
        .pc_load_en          (uc_pc_load_en),
        .pc_inc_en           (uc_pc_inc_en),
        .ac_load_en          (uc_ac_load_en),
        .flags_reset         (uc_flags_reset),
        .alu_op              (uc_alu_op),
        .alu_cin             (uc_alu_cin),
        .mem_write_en        (uc_mem_write_en),
        .mem_read_en         (uc_mem_read_en),
        .mem_addr_bus        (uc_mem_addr_bus_dp),
        .data_bus_in         (uc_data_bus_to_dp),     // From UC
        .mem_data_in         (mem_data_read_out),     // NEW: from RAM
        .sel_mem_data        (uc_sel_mem_data),       // NEW: mux select
        .in_switches         (in_switches),

        .pc_out              (dp_pc_out),
        .ac_out              (dp_ac_out),
        .mem_read_data       (dp_mem_read_data),
        .out_leds            (out_leds),
        .flag_n              (dp_flag_n),
        .flag_z              (dp_flag_z),
        .flag_c              (dp_flag_c),
        .flag_b              (dp_flag_b),
        .flag_v              (dp_flag_v)
    );

    // Instantiate the Memory RAM
    memoria_ram ram_inst (
        .clk        (clk),
        .wr_en      (mem_write_enable),
        .address    (mem_address),
        .data_in    (mem_data_write_in),
        .data_out   (mem_data_read_out)
    );

endmodule
