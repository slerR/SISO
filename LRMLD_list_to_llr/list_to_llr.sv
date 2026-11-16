`timescale 1ns / 1ps

module list_to_llr #(
    parameter N         = 8,
    parameter L         = 4,
    parameter METRIC_W  = 8,
    parameter LLR_W     = METRIC_W + 1
)(
    input  logic                        clk,
    input  logic                        i_valid,
    input  logic [METRIC_W - 1 : 0]     i_m     [0 : L - 1],
    input  logic [N - 1 : 0]            i_l     [0 : L - 1],

    output logic                        o_valid,
    output logic signed [LLR_W - 1 : 0] o_llr   [0 : N - 1]
);

    logic [L - 1 : 0] mask0 [0 : N - 1];
    logic [L - 1 : 0] mask1 [0 : N - 1];

    always_comb begin
        for (int j = 0; j < N; j++) begin
            for (int k = 0; k < L; k++) begin
                mask0[j][k] = (i_l[k][j] == 1'b0);
                mask1[j][k] = (i_l[k][j] == 1'b1);
            end
        end
    end

    logic [METRIC_W - 1 : 0] s0_comb [0 : N - 1];
    logic [METRIC_W - 1 : 0] s1_comb [0 : N - 1];

    generate
        for (genvar j = 0; j < N; j++) begin
            min_masked #(
                .W(METRIC_W),
                .N(L)
            ) u_min0 (
                .i_mask(mask0[j]),
                .i_vec (i_m),
                .o_min (s0_comb[j])
            );

            min_masked #(
                .W(METRIC_W),
                .N(L)
            ) u_min1 (
                .i_mask(mask1[j]),
                .i_vec (i_m),
                .o_min (s1_comb[j])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        for (int j = 0; j < N; j++) begin
            o_llr[j] <= $signed({1'b0, s1_comb[j]}) - $signed({1'b0, s0_comb[j]});
        end
        o_valid <= i_valid;
    end

endmodule