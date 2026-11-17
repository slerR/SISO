`timescale 1ns / 1ps

module siso_lrmld_n_8_l_16 #(
    parameter LLR_W = 6,
    parameter N     = 8,
    parameter L     = 16,
    localparam MLABEL_W  = 2,
    localparam METRIC_W  = LLR_W + $clog2(MLABEL_W),
    localparam LLR_OUT_W = METRIC_W + 1
)(
    input  logic                             clk,
    input  logic                             rst,
    input  logic                             i_valid,
    input  logic signed  [ LLR_W - 1 : 0]    i_llr   [0 : N - 1],

    output logic                             o_valid,
    output logic signed  [LLR_OUT_W - 1 : 0] o_llr   [0 : N - 1]
);

    logic                             i_v_r;
    logic signed  [   LLR_W - 1 : 0]  i_llr_r   [0 : N - 1];

    logic                             m_v_w;
    logic         [METRIC_W - 1 : 0]  m_m_w     [0 : L - 1];
    logic         [       N - 1 : 0]  m_l_w     [0 : L - 1];

    logic                             l_v_w;
    logic signed  [LLR_OUT_W - 1 : 0] l_llr_w   [0 : N - 1];

    logic                             o_v_r;
    logic signed  [LLR_OUT_W - 1 : 0] o_llr_r   [0 : N - 1];

    always_ff @(posedge clk) begin
        if (rst) begin
            i_v_r <= '0;
            for (int i = 0; i < N; i++) begin
                i_llr_r[i] <= '0;
            end
        end else begin
            i_v_r <= i_valid;
            for (int i = 0; i < N; i++) begin
                i_llr_r[i] <= i_llr[i];
            end
        end
    end

    top_8_L16_fsm0 #(
        .L     (L    ),
        .LLR_W (LLR_W),
        .IS_PAD(0    ),
        .FSM   (2'b00)
    ) u_rmld (
        .clk  (clk    ),
        .i_v  (i_v_r  ),
        .i_llr(i_llr_r),
        .o_m  (m_m_w  ),
        .o_l  (m_l_w  ),
        .o_v  (m_v_w  )
    );

    list_to_llr #(
        .N       (N       ),
        .L       (L       ),
        .METRIC_W(METRIC_W),
        .LLR_W   (LLR_OUT_W)
    ) u_llr (
        .clk    (clk    ),
        .i_valid(m_v_w  ),
        .i_m    (m_m_w  ),
        .i_l    (m_l_w  ),
        .o_valid(l_v_w  ),
        .o_llr  (l_llr_w)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            o_v_r <= '0;
            for (int i = 0; i < N; i++) begin
                o_llr_r[i] <= '0;
            end
        end else begin
            o_v_r <= l_v_w;
            for (int i = 0; i < N; i++) begin
                o_llr_r[i] <= l_llr_w[i];
            end
        end
    end

    assign o_valid = o_v_r;

    generate
        for (genvar i = 0; i < N; i++) begin
            assign o_llr[i] = o_llr_r[i];
        end
    endgenerate

endmodule