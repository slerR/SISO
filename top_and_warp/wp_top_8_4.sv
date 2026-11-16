`timescale 1ns / 1ps

module wp_top_8_4 #(
    parameter LLR_W   = 6,
    parameter N       = 8,
    parameter L       = 2,
    parameter M_WL    = LLR_W + $clog2(L),
    parameter N_COS   = 4,
    parameter N_WORDS = 1,
    parameter N_U     = 2,
    parameter K_A     = 2,
    parameter K_B     = 2,
    parameter logic [L - 1 : 0] LXY [0 : N_COS - 1][0 : N_WORDS - 1] = '{
            '{2'b00},
            '{2'b10},
            '{2'b01},
            '{2'b11}},
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL_UP_04_48 [0 : N_COS - 1][0 : N_U - 1] = '{
        '{4'b0000, 4'b1111},
        '{4'b0101, 4'b1010},
        '{4'b1100, 4'b0011},
        '{4'b1001, 4'b0110}},
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL_A_04_48 [0 : N_COS - 1][0 : K_A - 1] = '{
        '{4'b0000, 4'b1011},
        '{4'b0101, 4'b1110},
        '{4'b0110, 4'b1101},
        '{4'b0011, 4'b1000}},
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL_B_04_48 [0 : N_COS - 1][0 : K_B - 1] = '{
        '{4'b0000, 4'b1011},
        '{4'b0101, 4'b1110},
        '{4'b0110, 4'b1101},
        '{4'b0011, 4'b1000}}
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         i_valid,
    input  logic signed [LLR_W - 1 : 0]  i_llr  [0 : N - 1],

    output logic                         o_valid,
    output logic signed [(M_WL + 3) : 0] o_llr  [0 : N - 1]
);

    logic                         i_valid_r;
    logic signed [LLR_W - 1 : 0]  i_llr_r  [0 : N - 1];

    logic                         o_valid_w;
    logic signed [(M_WL + 3) : 0] o_llr_w  [0 : N - 1];

    always_ff @(posedge clk) begin
        if (rst) begin
            i_valid_r <= '0;
            for (int i = 0; i < N; i++) begin
                i_llr_r[i] <= '0;
            end
        end else begin
            i_valid_r <= i_valid;
            for (int i = 0; i < N; i++) begin
                i_llr_r[i] <= i_llr[i];
            end
        end
    end

    top_8_4 #(
        .LLR_W       (LLR_W       ),
        .N           (N           ),
        .L           (L           ),
        .M_WL        (M_WL        ),
        .N_COS       (N_COS       ),
        .N_WORDS     (N_WORDS     ),
        .N_U         (N_U         ),
        .K_A         (K_A         ),
        .K_B         (K_B         ),
        .LXY         (LXY         ),
        .TBL_UP_04_48(TBL_UP_04_48),
        .TBL_A_04_48 (TBL_A_04_48 ),
        .TBL_B_04_48 (TBL_B_04_48 )
    )top_8_4 (
        .clk    (clk      ),
        .rst    (rst      ),
        .i_valid(i_valid_r),
        .i_llr  (i_llr_r  ),
        .o_valid(o_valid_w),
        .o_llr  (o_llr_w  )
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            o_valid <= '0;
            for (int i = 0; i < N; i++) begin
                o_llr[i] <= '0;
            end
        end else begin
            o_valid <= o_valid_w;
            for (int i = 0; i < N; i++) begin
                o_llr[i] <= o_llr_w[i];
            end
        end
    end

endmodule