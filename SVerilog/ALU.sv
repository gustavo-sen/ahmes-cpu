module ALU (
    input  logic [3:0]  operacao,
    input  logic [7:0]  operA,
    input  logic [7:0]  operB,
    input  logic        Cin,
    output logic [7:0]  result,
    output logic        N,
    output logic        Z,
    output logic        C,
    output logic        B,
    output logic        V
);

    // Opcodes
    localparam logic [3:0]
        ADIC = 4'b0001,
        SUB  = 4'b0010,
        OU   = 4'b0011,
        E    = 4'b0100,
        NAO  = 4'b0101,
        XOU  = 4'b0110,
        DLE  = 4'b0111,
        DLD  = 4'b1000,
        DAE  = 4'b1001,
        DAD  = 4'b1010;

    logic [8:0] temp;
    logic [7:0] result_tmp;
    logic n_flag, z_flag, c_flag, b_flag, v_flag;

    always_comb begin
        // Defaults
        n_flag = 1'b0;
        z_flag = 1'b0;
        c_flag = 1'b0;
        b_flag = 1'b0;
        v_flag = 1'b0;
        result_tmp = 8'b0;
        temp = 9'b0;

        case (operacao)
            ADIC: begin
                temp = {1'b0, operA} + {1'b0, operB};
                result_tmp = temp[7:0];
                c_flag = temp[8];

                if ((operA[7] == operB[7]) && (operA[7] != result_tmp[7]))
                    v_flag = 1'b1;
            end

            SUB: begin
                temp = {1'b0, operA} - {1'b0, operB};
                result_tmp = temp[7:0];
                b_flag = temp[8];  // Borrow

                if ((operA[7] != operB[7]) && (operA[7] != result_tmp[7]))
                    v_flag = 1'b1;
            end

            OU:    result_tmp = operA | operB;
            E:     result_tmp = operA & operB;
            NAO:   result_tmp = ~operA;
            XOU:   result_tmp = operA ^ operB;

            DLE: begin
                c_flag = operA[7];
                result_tmp = {operA[6:0], Cin};
            end

            DAE: begin
                c_flag = operA[7];
                result_tmp = {operA[6:0], 1'b0};
            end

            DLD: begin
                c_flag = operA[0];
                result_tmp = {Cin, operA[7:1]};
            end

            DAD: begin
                c_flag = operA[0];
                result_tmp = {1'b0, operA[7:1]};
            end

            default: result_tmp = 8'b0;
        endcase

        // Common flags
        z_flag = (result_tmp == 8'b0);
        n_flag = result_tmp[7];

        // Outputs
        result = result_tmp;
        N = n_flag;
        Z = z_flag;
        C = c_flag;
        B = b_flag;
        V = v_flag;
    end

endmodule
