module CPU (
    input  logic        clk,
    input  logic        rst,
    input  logic [3:0]  buttons,   // 4 botões como entrada
    output logic [3:0]  leds,      // 4 LEDs como saída
    input  logic        Cin,
    output logic [7:0]  data_out   // acumulador visível
);

    // Registradores internos
    logic [7:0] ACC;   // Acumulador
    logic [7:0] IR;    // Instruction Register
    logic [7:0] PC;    // Program Counter

    // Decodificação
    logic [3:0] opcode;
    logic [7:0] operand;

    // Flags
    logic N, Z, C, B, V;

    // ULA
    logic [7:0] alu_result;

    ALU alu_inst (
        .operacao (opcode),
        .operA    (ACC),
        .operB    (operand),
        .Cin      (Cin),
        .result   (alu_result),
        .N        (N),
        .Z        (Z),
        .C        (C),
        .B        (B),
        .V        (V)
    );

    // memória interna
    logic [7:0] MEM [0:255];

    // Inicialização
    initial begin
        PC  = 8'd0;
        ACC = 8'd0;
        IR  = 8'd0;
        leds = 4'b0000;
    end

    // Ciclo fetch-decode-execute
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC  <= 8'd0;
            ACC <= 8'd0;
            IR  <= 8'd0;
            leds <= 4'b0000;
        end else begin
            // FETCH
            IR <= MEM[PC];
            PC <= PC + 1;

            // DECODE
            opcode  <= IR[7:4];
            operand <= MEM[PC];
            PC <= PC + 1;

            // EXECUTE
            case (opcode)
                4'b0001: ACC <= alu_result;    // ADD
                4'b0010: ACC <= alu_result;    // SUB
                4'b0011: ACC <= alu_result;    // OR
                4'b0100: ACC <= alu_result;    // AND
                4'b0101: ACC <= alu_result;    // NOT
                4'b0110: ACC <= operand;       // LDA imediato
                4'b0111: MEM[operand] <= ACC;  // STA 
                4'b1000: ACC <= MEM[operand];  // LDA da RAM

                // IN
                4'b1001: begin
                    if (operand >= 8'hF0 && operand <= 8'hF3)
                        ACC <= {4'b0000, buttons}; 
                    else
                        ACC <= 8'h00;
                end

                // OUT 
                4'b1010: begin
                    if (operand >= 8'hF4 && operand <= 8'hF7)
                        leds <= ACC[3:0];  
                end

                4'b1111: PC <= PC; // HLT

                default: ACC <= ACC; // NOP
            endcase
        end
    end

    // Saída principal
    assign data_out = ACC;

endmodule
