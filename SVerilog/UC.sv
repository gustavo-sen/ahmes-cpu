module UC (
    input  logic        clk,
    input  logic        reset,
    input  logic [7:0]  data_bus,   // dado da memória (operandos ou instrução fetch)
    input  logic [7:0]  instr_bus,   

    input  logic [3:0]  in_port,    // botões
    output logic [3:0]  out_port,   // LEDs 

    // ALU interface
    output logic [3:0]  alu_op,
    output logic [7:0]  alu_operA,
    output logic [7:0]  alu_operB,
    output logic        alu_Cin,

    // memória ainda a ser implementada
    output logic [7:0]  address_bus,
    output logic [7:0]  data_out,
    output logic        mem_we,
    output logic        mem_re,

    // acc
    output logic        acc_load,
    output logic [7:0]  acc_in,
    input  logic [7:0]  acc_out,

    // pc
    output logic        pc_inc,
    output logic        pc_load,
    output logic [7:0]  pc_in,
    input  logic [7:0]  pc_out,

    // registradores internos (debug/observabilidade)
    output logic        ERROR
);

    // registradores internos
    logic [7:0] instr_reg; // armazenar instrução fetch

    // ALU
    logic [7:0] alu_result;
    logic       alu_N, alu_Z, alu_C, alu_B, alu_V;

    ALU alu0 (
        .operacao(alu_op),
        .operA(acc_out),
        .operB(data_bus),
        .Cin(alu_Cin),
        .result(alu_result),
        .N(alu_N),
        .Z(alu_Z),
        .C(alu_C),
        .B(alu_B),
        .V(alu_V)
    );

    // Sinais de controle
    logic mem_read, mem_write;

    // Estados da FSM
    typedef enum logic [1:0] {
        FETCH  = 2'b00,
        DECODE = 2'b01,
        EXEC   = 2'b10,
        UPDATE = 2'b11
    } state_t;

    state_t state, next_state;

    // opcode
    localparam logic [7:0]
        NOP   = 8'b0000_0000,
        STA   = 8'b0001_0000,
        LDA   = 8'b0010_0000,
        ADD   = 8'b0011_0000,
        IOR   = 8'b0100_0000,
        IAND  = 8'b0101_0000,
        INOT  = 8'b0110_0000,
        SUB   = 8'b0111_0000,
        JMP   = 8'b1000_0000,
        JN    = 8'b1001_0000,
        JP    = 8'b1001_0100,
        JV    = 8'b1001_1000,
        JNV   = 8'b1001_1100,
        JZ    = 8'b1010_0000,
        JNZ   = 8'b1010_0100,
        JC    = 8'b1011_0000,
        JNC   = 8'b1011_0100,
        JB    = 8'b1011_1000,
        JNB   = 8'b1011_1100,
        SHR   = 8'b1110_0000,
        SHL   = 8'b1110_0001,
        IROR  = 8'b1110_0010,
        IROL  = 8'b1110_0011,
        HLT   = 8'b1111_0000,
        IN    = 8'b0000_0111,
        OUT   = 8'b0000_1000;

    localparam logic [3:0]
        ULA_ADD = 4'b0001,
        ULA_SUB = 4'b0010,
        ULA_OU  = 4'b0011,
        ULA_E   = 4'b0100,
        ULA_NAO = 4'b0101,
        ULA_XOU = 4'b0110,
        ULA_DLE = 4'b0111,
        ULA_DLD = 4'b1000,
        ULA_DAE = 4'b1001,
        ULA_DAD = 4'b1010;

    // FSM Sequencial
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= FETCH;
            pc_reg <= 8'b0;
            acc_reg <= 8'b0;
            instr_reg <= 8'b0;
            out_port <= 4'b0;
        end else begin
            state <= next_state;

            // Atualização de registradores
            if(acc_we) acc_reg <= alu_result;
            else if(io_re) acc_reg <= {4'b0, in_port};
            else if(load_from_mem) acc_reg <= data_bus;

            if(io_we) out_port <= acc_reg[3:0];

            if(pc_load) pc_reg <= data_bus;
            else if(pc_inc) pc_reg <= pc_reg + 1;

            // mem_write / mem_read pulsos
            if(mem_write) data_out <= acc_reg;
            address_bus <= data_bus; // simplificado
        end
    end

    // FSM combinacional
    always_comb begin
        // defaults
        alu_op        = 4'b0000;
        alu_operA     = acc_reg;
        alu_operB     = data_bus;
        alu_Cin       = 1'b0;
        acc_we        = 0;
        pc_inc        = 0;
        pc_load       = 0;
        io_we         = 0;
        io_re         = 0;
        load_from_mem = 0;
        mem_write     = 0;
        mem_re        = 0;
        ERROR         = 0;
        next_state    = state;

        case(state)
            FETCH: begin
                // ler instrução da memória (data_bus) -> instr_reg
                instr_reg = instr_bus;
                pc_inc    = 1'b1;
                next_state = DECODE;
            end

            DECODE: begin
                // prepara sinais para execução
                next_state = EXEC;
            end

            EXEC: begin
                case(instr_reg)
                    NOP: ;
                    ADD: begin alu_op = ULA_ADD; acc_we=1; end
                    SUB: begin alu_op = ULA_SUB; acc_we=1; end
                    IOR: begin alu_op = ULA_OU; acc_we=1; end
                    XOU: begin alu_op = ULA_XOU; acc_we; end
                    IAND: begin alu_op = ULA_E; acc_we=1; end
                    INOT: begin alu_op = ULA_NAO; acc_we=1; end
                    LDA: begin mem_re = 1; load_from_mem = 1; end
                    STA: begin mem_write = 1; end
                    JMP: pc_load = 1; 
                    JN: if(alu_N) pc_load=1;
                    JP: if(!alu_N) pc_load=1;
                    JV: if(alu_V) pc_load=1;
                    JNV: if(!alu_V) pc_load=1;
                    JZ: if(alu_Z) pc_load=1;
                    JNZ: if(!alu_Z) pc_load=1;
                    JC: if(alu_C) pc_load=1;
                    JNC: if(!alu_C) pc_load=1;
                    JB: if(alu_B) pc_load=1;
                    JNB: if(!alu_B) pc_load=1;
                    SHR: begin alu_op = ULA_DAD; acc_we=1; end
                    SHL: begin alu_op = ULA_DLE; acc_we=1; end
                    IROR: begin alu_op = ULA_DLD; acc_we=1; end
                    IROL: begin alu_op = ULA_DLE; acc_we=1; end
                    IN: begin io_re=1; end
                    OUT: begin io_we=1; end
                    HLT: begin next_state = EXEC; end // para máquina
                    default: ERROR=1;
                endcase
                next_state = UPDATE;
            end

            UPDATE: begin
                next_state = FETCH; // próximo ciclo: fetch da nova instrução
            end

            default: next_state = FETCH;
        endcase
    end

    // expose registradores
    assign ACC = acc_reg;
    assign PC  = pc_reg;

endmodule
