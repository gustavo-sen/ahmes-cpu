module UC (
    input  logic        clk,
    input  logic        reset,
    input  logic [7:0]  data_bus,   // dado da memória 
    input  logic [7:0]  instr_bus,   

    input  logic [3:0]  in_port,    // botões
    output logic [3:0]  out_port,   // LEDs 

    // ALU interface
    output logic [3:0]  alu_op,
    output logic [7:0]  alu_operA,
    output logic [7:0]  alu_operB,
    output logic        alu_Cin,

    // memória
    output logic [7:0]  address_bus,
    output logic [7:0]  data_out,
    output logic        mem_we,
    output logic        mem_re,

    // acc
    output logic        load_ac,
    output logic [7:0]  data_in,
    input  logic [7:0]  ac_out,

    // pc
    output logic        inc,
    output logic        load,
    output logic [7:0]  pc_in,
    input  logic [7:0]  pc_out,

    // debug
    output logic        ERROR
);

    // registradores internos
    logic [7:0] instr_reg;     // armazenar instrução fetch
    logic [7:0] pc_reg;        // contador de programa
    logic [7:0] acc_reg;       // acumulador
    
    // ALU
    logic [7:0] alu_result;
    logic       alu_N, alu_Z, alu_C, alu_B, alu_V;

    ALU alu0 (
        .operacao(alu_op),
        .operA(acc_reg),
        .operB(data_bus),
        .Cin(alu_Cin),
        .result(alu_result),
        .N(alu_N),
        .Z(alu_Z),
        .C(alu_C),
        .B(alu_B),
        .V(alu_V)
    );

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
        XOR   = 8'b0001_1000,
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
        ULA_XOU = 4'b0110,
        ULA_E   = 4'b0100,
        ULA_NAO = 4'b0101,
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
            instr_reg <= instr_bus;

            // Atualização do acumulador 
            if(load_ac) 
                acc_reg <= alu_result;
            else if(io_re) 
                acc_reg <= {4'b0, in_port};
            else if(load_from_mem) 
                acc_reg <= data_bus;

            // Atualização da saída
            if(io_we) 
                out_port <= acc_reg[3:0];

            // Atualização do PC
            if(load) 
                pc_reg <= data_bus;
            else if(inc) 
                pc_reg <= pc_reg + 1;

            // Conexões para memória
            data_out <= acc_reg;
            address_bus <= (state == FETCH) ? pc_reg : data_bus;
        end
    end

    // Sinais auxiliares 
    logic load_from_mem;
    logic io_re, io_we;

    // FSM combinacional - Geração DIRETA dos sinais de controle
    always_comb begin
        alu_op = 4'b0000;
        alu_operA = acc_reg;
        alu_operB = data_bus;
        alu_Cin = 1'b0;
        load_ac = 1'b0;      
        inc = 1'b0;          
        load = 1'b0;         
        io_we = 1'b0;
        io_re = 1'b0;
        load_from_mem = 1'b0;
        mem_we = 1'b0;
        mem_re = 1'b0;
        ERROR = 1'b0;
        next_state = state;

        case(state)
            FETCH: begin
                mem_re = 1'b1;    // Ler memória para fetch
                inc = 1'b1;       // Incrementar PC ← DIRETO!
                next_state = DECODE;
            end

            DECODE: begin
                if (instr_reg != NOP && instr_reg != HLT) begin
                    mem_re = 1'b1;  // Ler operando
                end
                next_state = EXEC;
            end

            EXEC: begin
                case(instr_reg)
                    NOP: begin /* No operation */ end
                    ADD: begin 
                        alu_op = ULA_ADD; 
                        load_ac = 1'b1;  
                    end
                    SUB: begin 
                        alu_op = ULA_SUB; 
                        load_ac = 1'b1;  
                    end
                    IOR: begin 
                        alu_op = ULA_OU; 
                        load_ac = 1'b1;  
                    end
                    XOU: begin 
                        alu_op = ULA_XOU; 
                        load_ac = 1'b1;  
                    end
                    IAND: begin 
                        alu_op = ULA_E; 
                        load_ac = 1'b1;  
                    end
                    INOT: begin 
                        alu_op = ULA_NAO; 
                        load_ac = 1'b1;  
                    end
                    LDA: begin 
                        mem_re = 1'b1; 
                        load_from_mem = 1'b1; 
                    end
                    STA: begin 
                        mem_we = 1'b1; 
                    end
                    JMP: begin 
                        load = 1'b1;  
                    end
                    JN: if(alu_N) load = 1'b1;     
                    JP: if(!alu_N) load = 1'b1;    
                    JV: if(alu_V) load = 1'b1;     
                    JNV: if(!alu_V) load = 1'b1;   
                    JZ: if(alu_Z) load = 1'b1;     
                    JNZ: if(!alu_Z) load = 1'b1;   
                    JC: if(alu_C) load = 1'b1;     
                    JNC: if(!alu_C) load = 1'b1;   
                    JB: if(alu_B) load = 1'b1;     
                    JNB: if(!alu_B) load = 1'b1;   
                    SHR: begin 
                        alu_op = ULA_DAD; 
                        load_ac = 1'b1;  
                    end
                    SHL: begin 
                        alu_op = ULA_DLE; 
                        load_ac = 1'b1;  
                    end
                    IROR: begin 
                        alu_op = ULA_DLD; 
                        load_ac = 1'b1;  
                    end
                    IROL: begin 
                        alu_op = ULA_DAE; 
                        load_ac = 1'b1;  
                    end
                    IN: begin 
                        io_re = 1'b1; 
                    end
                    OUT: begin 
                        io_we = 1'b1; 
                    end
                    HLT: begin 
                        next_state = EXEC;
                    end
                    default: ERROR = 1'b1;
                endcase
                
                if (instr_reg != HLT) begin
                    next_state = UPDATE;
                end
            end

            UPDATE: begin
                next_state = FETCH;
            end

            default: next_state = FETCH;
        endcase
    end

    // Conexões simples
    assign data_in = data_bus;
    assign pc_in = data_bus;

endmodule