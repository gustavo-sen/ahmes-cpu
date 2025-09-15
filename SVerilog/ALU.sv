module ALU (
    // input
    input  logic [3:0] operacao, 
    input  logic [7:0] operA,    
    input  logic [7:0] operB,    
    input  logic       Cin,      // Carry in

    //output
    output logic [7:0] result,   
    output logic       N,        // (Negative flag)
    output logic       Z,        // (Zero flag)
    output logic       C,        // (Carry flag)
    output logic       B,        // (Borrow flag)
    output logic       V         // (Overflow flag)
);

    // Opcodes
    localparam ADIC = 4'b0001;
    localparam SUB  = 4'b0010; 
    localparam OU   = 4'b0011; 
    localparam E    = 4'b0100; 
    localparam NAO  = 4'b0101; 
    localparam XOU  = 4'b0110; 
    localparam DLE  = 4'b0111; // Rotação para Esquerda (Rotate Left)
    localparam DLD  = 4'b1000; // Rotação para Direita (Rotate Right)
    localparam DAE  = 4'b1001; // Deslocamento Aritmético para Esquerda (Shift Arith. Left)
    localparam DAD  = 4'b1010; // Deslocamento Lógico para Direita (Shift Logical Right)

    always @(*) begin
        logic [8:0] temp;

        result = 8'h00;
        N = 1'b0;
        Z = 1'b0;
        C = 1'b0;
        B = 1'b0;
        V = 1'b0;

        case (operacao)
            ADIC: begin
                temp = {1'b0, operA} + {1'b0, operB};
                result = temp[7:0];
                C = temp[8];
                V = (operA[7] == operB[7]) && (operA[7] != result[7]);
                B = 1'b0;
            end

            SUB: begin
                temp = {1'b0, operA} - {1'b0, operB};
                result = temp[7:0];
                B = temp[8];
                V = (operA[7] != operB[7]) && (operA[7] != result[7]);
                C = 1'b0;
            end

            OU:     begin result = operA | operB; end
            E:      begin result = operA & operB; end
            NAO:    begin result = ~operA; end
            XOU:    begin result = operA ^ operB; end

            DLE: begin
                C = operA[7];
                result = {operA[6:0], Cin};
            end

            DAE: begin
                C = operA[7];
                result = {operA[6:0], 1'b0};
            end

            DLD: begin
                C = operA[0];
                result = {Cin, operA[7:1]};
            end

            DAD: begin
                C = operA[0];
                result = {1'b0, operA[7:1]};
            end

            default: begin
                result = 8'b0;
                Z = 0;
                N = 0;
                C = 0;
                V = 0;
                B = 0;
            end
        endcase

          // Flags comuns
        if (result == 8'b0)
            Z = 1;
        else
            Z = 0;

        N = result[7];
    end

endmodule