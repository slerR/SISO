module min_masked#(
    parameter                   W,
    parameter                   N
)(
    input  logic [N - 1 : 0] i_mask,
    input  logic [W - 1 : 0] i_vec [0 : N - 1], // unsorted vector
    output logic [W - 1 : 0] o_min
);

    localparam LEVELS = $clog2(N);
    
    logic [W - 1 : 0] operands [0 : N - 1 ];
    logic [W - 1 : 0] lvl      [0 : LEVELS][0 : N - 1];
    
    always_comb begin
        for (int i = 0; i < N; i++) begin
            operands[i] = i_mask[i] ? i_vec[i] : '1;
        end
    end
    
    generate
        for (genvar i = 0; i < N; i++) begin
            assign lvl[0][i] = operands[i];
        end
        for (genvar j = 0; j < LEVELS; j++) begin
            localparam STEP = 1 << j;
            for (genvar k = 0; k < N; k++) begin
                if (k + STEP < N) begin
                    min2 #(.W(W)) u_min2 (
                        .i_x(lvl[j][k]),
                        .i_y(lvl[j][k + STEP]),
                        .o_min(lvl[j+1][k])
                    );
                end else begin
                    assign lvl[j+1][k] = lvl[j][k];
                end
            end
        end
    endgenerate

    assign o_min = lvl[LEVELS][0];
endmodule