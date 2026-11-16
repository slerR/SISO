`timescale 1ns / 1ps

// подумать над M_W+1
module form_llr#(
    parameter M_W_ADIB,
    parameter M_W_BD,
    parameter L,
    parameter N_COS,
    parameter M_W = ((M_W_ADIB > M_W_BD) ? M_W_ADIB : M_W_BD) + 1
)(
    input  logic                        clk,
    input  logic                        i_valid,
    input  logic [  M_W_BD - 1 : 0]     i_bd   [0 : N_COS - 1],
    input  logic [M_W_ADIB - 1 : 0]     i_adib [0 : N_COS - 1][0 : L - 1][0 : 1],

    output logic                        o_valid,
    output logic signed [M_W : 0]       o_llr  [0 : L - 1]
);

    logic [M_W - 1 : 0] s0_comb [0 : L - 1];
    logic [M_W - 1 : 0] s1_comb [0 : L - 1];
    logic [M_W - 1 : 0] s0_reg  [0 : L - 1];
    logic [M_W - 1 : 0] s1_reg  [0 : L - 1];

    logic [M_W - 1 : 0] sum0 [0 : N_COS - 1][0 : L - 1];
    logic [M_W - 1 : 0] sum1 [0 : N_COS - 1][0 : L - 1];
    
    logic [      1 : 0] valid_d;

    generate
        for (genvar c = 0; c < N_COS; c++) begin
            for (genvar i = 0; i < L; i++) begin
                assign sum0[c][i] = i_bd[c] + i_adib[c][i][0];
                assign sum1[c][i] = i_bd[c] + i_adib[c][i][1];
            end
        end
    endgenerate

    generate
        for (genvar i = 0; i < L; i++) begin
            logic [M_W - 1 : 0] v0 [0 : N_COS - 1];
            logic [M_W - 1 : 0] v1 [0 : N_COS - 1];
            
            for (genvar c = 0; c < N_COS; c++) begin
                assign v0[c] = sum0[c][i];
                assign v1[c] = sum1[c][i];
            end
            
            min_masked #(
                .W(M_W  ), 
                .N(N_COS)
            )u_min0 (
                .i_mask('1        ),
                .i_vec (v0        ),
                .o_min (s0_comb[i])
            );
            
            min_masked #(
                .W(M_W  ), 
                .N(N_COS)
            )u_min1 (
                .i_mask('1        ),
                .i_vec (v1        ),
                .o_min (s1_comb[i])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        for (int i = 0; i < L; i++) begin
            s0_reg[i] <= s0_comb[i];
            s1_reg[i] <= s1_comb[i];
        end
        valid_d <= {valid_d[0], i_valid};
    end

    always_ff @(posedge clk) begin
        for (int i = 0; i < L; i++) begin
            o_llr[i] <= $signed({1'b0, s1_reg[i]}) - $signed({1'b0, s0_reg[i]});
        end
    end

    assign o_valid = valid_d[1];

endmodule