module UC (
    input  logic        clk,
    input  logic        reset,
    input  logic [7:0]  data_bus_from_mem, // Data from external memory, connected to datapath's data_bus_in
    input  logic [7:0]  instr_bus,         // Instruction from external memory

    // Interface to Datapath
    output logic        pc_load_en,
    output logic        pc_inc_en,
    output logic        ac_load_en,
    output logic        flags_reset,
    output logic [3:0]  alu_op,
    output logic        alu_cin,
    output logic        mem_write_en,
    output logic        mem_read_en,
    output logic [7:0]  mem_addr_bus_dp,   // Address bus for Datapath (Memory/IO)
    output logic [7:0]  data_bus_to_dp,    // Data to Datapath (for writes, e.g., STA, or operands)
    output logic        sel_mem_data,      // select between mem_read_data_dp and data_bus_to_dp

    input  logic [7:0]  pc_out_dp,         // PC output from Datapath
    input  logic [7:0]  ac_out_dp,         // Accumulator output from Datapath
    input  logic [7:0]  mem_read_data_dp,  // Data read from Datapath (Memory/IO)
    input  logic        flag_n_dp,         // Negative flag from Datapath
    input  logic        flag_z_dp,         // Zero flag from Datapath
    input  logic        flag_c_dp,         // Carry flag from Datapath
    input  logic        flag_b_dp,         // Borrow flag from Datapath
    input  logic        flag_v_dp,         // Overflow flag from Datapath

    // Debug output
    output logic        ERROR
);

    // Internal register for fetched instruction
    logic [7:0] instr_reg;

    // Memory-mapped I/O addresses
    localparam LED_ADDR    = 8'hF0;
    localparam SWITCH_ADDR = 8'hF4;

    // States of the FSM
    typedef enum logic [1:0] {
        FETCH  = 2'b00,
        DECODE = 2'b01,
        EXEC   = 2'b10,
        UPDATE = 2'b11
    } state_t;

    state_t state, next_state;

    // opcode definitions
    localparam logic [7:0]
        NOP   = 8'b0000_0000,
        STA   = 8'b0001_0000,
        LDA   = 8'b0010_0000,
        ADD   = 8'b0011_0000,
        IOR   = 8'b0100_0000,
        XOR   = 8'b0001_1000,
        IAND  = 8'b0101_0000, 
        INOT  = 8'b0110_0000, 
        SUB   = 8'b1000_0000,
        JMP   = 8'b1001_0000,
        JN    = 8'b1010_0000,
        JP    = 8'b1010_0100,
        JV    = 8'b1010_1000,
        JNV   = 8'b1010_1100,
        JZ    = 8'b1011_0000,
        JNZ   = 8'b1011_0100,
        JC    = 8'b1100_0000,
        JNC   = 8'b1100_0100,
        JB    = 8'b1100_1000,
        JNB   = 8'b1100_1100,
        SHR   = 8'b1101_0000,
        SHL   = 8'b1101_0001,
        IROR  = 8'b1101_0010,
        IROL  = 8'b1101_0011,
        HLT   = 8'b1111_0000;

    // ALU operation codes
    localparam logic [3:0]
        ULA_ADD = 4'b0001,
        ULA_SUB = 4'b0010,
        ULA_OU  = 4'b0011,
        ULA_E   = 4'b0100,
        ULA_NAO = 4'b0101,
        ULA_XOU = 4'b0110,
        ULA_DLE = 4'b0111, // Shift Left
        ULA_DLD = 4'b1000, // Rotate Left
        ULA_DAE = 4'b1001, // Shift Right
        ULA_DAD = 4'b1010; // Rotate Right

    // FSM Sequential Logic
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state       <= FETCH;
            instr_reg   <= 8'h00;
            flags_reset <= 1'b1;
        end else begin
            state       <= next_state;
            instr_reg   <= instr_bus;
            flags_reset <= 1'b0;
        end
    end

    // FSM Combinational Logic
    always_comb begin
        // Defaults
        pc_load_en      = 1'b0;
        pc_inc_en       = 1'b0;
        ac_load_en      = 1'b0;
        alu_op          = 4'b0000;
        alu_cin         = 1'b0;
        mem_write_en    = 1'b0;
        mem_read_en     = 1'b0;
        mem_addr_bus_dp = 8'h00;
        data_bus_to_dp  = 8'h00;
        sel_mem_data    = 1'b0;   // default: use data_bus_to_dp
        ERROR           = 1'b0;
        next_state      = state;

        case(state)
            FETCH: begin
                mem_read_en     = 1'b1;
                mem_addr_bus_dp = pc_out_dp;
                pc_inc_en       = 1'b1;
                next_state      = DECODE;
            end

            DECODE: begin
                if (instr_reg != NOP && instr_reg != HLT &&
                    instr_reg != JMP && instr_reg != JN && instr_reg != JP &&
                    instr_reg != JV && instr_reg != JNV && instr_reg != JZ &&
                    instr_reg != JNZ && instr_reg != JC && instr_reg != JNC &&
                    instr_reg != JB && instr_reg != JNB &&
                    instr_reg != INOT && instr_reg != SHR && instr_reg != SHL &&
                    instr_reg != IROR && instr_reg != IROL) begin
                    mem_read_en     = 1'b1;
                    mem_addr_bus_dp = data_bus_from_mem;
                end
                next_state = EXEC;
            end

            EXEC: begin
                data_bus_to_dp = data_bus_from_mem;

                case(instr_reg)
                    NOP: begin end

                    // ALU ops
                    ADD: begin alu_op = ULA_ADD; ac_load_en = 1'b1; sel_mem_data=1'b1; end
                    SUB: begin alu_op = ULA_SUB; ac_load_en = 1'b1; sel_mem_data=1'b1; end
                    IOR: begin alu_op = ULA_OU;  ac_load_en = 1'b1; sel_mem_data=1'b1; end
                    XOR: begin alu_op = ULA_XOU; ac_load_en = 1'b1; sel_mem_data=1'b1; end
                    IAND:begin alu_op = ULA_E;   ac_load_en = 1'b1; sel_mem_data=1'b1; end
                    INOT:begin alu_op = ULA_NAO; ac_load_en = 1'b1; data_bus_to_dp=8'h00; end

                    // Data Transfer
                    LDA: begin
                        alu_op       = ULA_ADD;
                        ac_load_en   = 1'b1;
                        sel_mem_data = 1'b1; // load from memory
                    end
                    STA: begin
                        mem_write_en    = 1'b1;
                        mem_addr_bus_dp = data_bus_from_mem;
                        data_bus_to_dp  = ac_out_dp;
                    end

                    // Jumps
                    JMP:  begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JN:   if(flag_n_dp)  begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JP:   if(!flag_n_dp) begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JV:   if(flag_v_dp)  begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JNV:  if(!flag_v_dp) begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JZ:   if(flag_z_dp)  begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JNZ:  if(!flag_z_dp) begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JC:   if(flag_c_dp)  begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JNC:  if(!flag_c_dp) begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JB:   if(flag_b_dp)  begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end
                    JNB:  if(!flag_b_dp) begin pc_load_en=1'b1; data_bus_to_dp=data_bus_from_mem; end

                    // Shifts / Rotates
                    SHR: begin alu_op=ULA_DAD; ac_load_en=1'b1; data_bus_to_dp=8'h00; end
                    SHL: begin alu_op=ULA_DLE; ac_load_en=1'b1; data_bus_to_dp=8'h00; end
                    IROR:begin alu_op=ULA_DLD; ac_load_en=1'b1; data_bus_to_dp=8'h00; end
                    IROL:begin alu_op=ULA_DAE; ac_load_en=1'b1; data_bus_to_dp=8'h00; end

                    HLT: begin
                        next_state = EXEC;
                    end

                    default: ERROR = 1'b1;
                endcase

                if (instr_reg != HLT) next_state = UPDATE;
            end

            UPDATE: begin
                next_state = FETCH;
            end

            default: next_state = FETCH;
        endcase
    end

endmodule
