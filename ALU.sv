module ALU (
    input  [3:0] operacao,
    input  [7:0] operA,
    input  [7:0] operB,
    input        Cin,
    output reg [7:0] result,
    output reg N,
    output reg Z,
    output reg C,
    output reg B,
    output reg V
);

    // Definição dos códigos das operações
    localparam ADIC = 4'b0001;
    localparam SUB  = 4'b0010;
    localparam OU   = 4'b0011;
    localparam E    = 4'b0100;
    localparam NAO  = 4'b0101;
    localparam DLE  = 4'b0110;
    localparam DLD  = 4'b0111;
    localparam DAE  = 4'b1000;
    localparam DAD  = 4'b1001;

    reg [8:0] temp;

    always @(*) begin
        // Defaults
        result = 8'b0;
        N = 0;
        Z = 0;
        C = 0;
        B = 0;
        V = 0;
        temp = 9'b0;

        case (operacao)
            ADIC: begin
                temp = {1'b0, operA} + {1'b0, operB};
                result = temp[7:0];
                C = temp[8];
                if ((operA[7] == operB[7]) && (operA[7] != result[7]))
                    V = 1;
                else
                    V = 0;
            end

            SUB: begin
                temp = {1'b0, operA} - {1'b0, operB};
                result = temp[7:0];
                B = temp[8];
                if ((operA[7] != operB[7]) && (operA[7] != result[7]))
                    V = 1;
                else
                    V = 0;
            end

            OU:    result = operA | operB;
            E:     result = operA & operB;
            NAO:   result = ~operA;

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
