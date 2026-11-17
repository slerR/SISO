module top_8_L16_fsm0 #(
    parameter     L           = 16,
    parameter     LLR_W       = 6,
    parameter     IS_PAD      = 0,
    parameter logic [1:0] FSM = 2'b00,
    localparam     MLABEL_W   = 2,
    localparam     METRIC_W   = LLR_W + $clog2(MLABEL_W)
)(
    input  logic                            clk,
    input  logic                            i_v,
    input  logic signed  [   LLR_W - 1 : 0] i_llr [0 : 7   ],
    output logic         [METRIC_W - 1 : 0] o_m   [0 : L - 1],
    output logic         [          7 : 0] o_l   [0 : L - 1],
    output logic                            o_v
);

    localparam N_COS = 2;

    localparam logic [2 - 1 : 0] DECOMP_0 [0 : 2 - 1][0 : 2 - 1] = '{
        '{2'b00, 2'b11},
        '{2'b01, 2'b10}
    };

    localparam logic [2 - 1 : 0] TBL_0 [0 : 2 - 1][0 : 2 - 1] = '{
        '{2'b0_0, 2'b1_1},
        '{2'b1_0, 2'b0_1}
    };

    logic [14 - 1 : 0] m_m_0_2_m [0 : N_COS - 1];
    logic [4 - 1 : 0] m_m_0_2_l [0 : N_COS - 1];
    logic              m_m_0_2_v;

    logic [14 - 1 : 0] m_m_2_4_m [0 : N_COS - 1];
    logic [4 - 1 : 0] m_m_2_4_l [0 : N_COS - 1];
    logic              m_m_2_4_v;

    logic [14 - 1 : 0] m_m_4_6_m [0 : N_COS - 1];
    logic [4 - 1 : 0] m_m_4_6_l [0 : N_COS - 1];
    logic              m_m_4_6_v;

    logic [14 - 1 : 0] m_m_6_8_m [0 : N_COS - 1];
    logic [4 - 1 : 0] m_m_6_8_l [0 : N_COS - 1];
    logic              m_m_6_8_v;

    logic [28 - 1 : 0] m_c_0_4_m [0 : N_COS - 1];
    logic [16 - 1 : 0] m_c_0_4_l [0 : N_COS - 1];
    logic              m_c_0_4_v;

    logic [28 - 1 : 0] m_c_4_8_m [0 : N_COS - 1];
    logic [16 - 1 : 0] m_c_4_8_l [0 : N_COS - 1];
    logic              m_c_4_8_v;

    localparam logic [1:0] TOP_FSM = (FSM == 2'b00) ? 2'b00 : (FSM == 2'b01) ? 2'b00 : (FSM == 2'b10) ? 2'b01 : 2'b10;

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (2             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_0_2 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[0 : 1] ),
        .o_metrics(m_m_0_2_m           ),
        .o_labels (m_m_0_2_l           ),
        .o_valid  (m_m_0_2_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (2             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_2_4 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[2 : 3] ),
        .o_metrics(m_m_2_4_m           ),
        .o_labels (m_m_2_4_l           ),
        .o_valid  (m_m_2_4_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (2             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_4_6 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[4 : 5] ),
        .o_metrics(m_m_4_6_m           ),
        .o_labels (m_m_4_6_l           ),
        .o_valid  (m_m_4_6_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (2             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_6_8 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[6 : 7] ),
        .o_metrics(m_m_6_8_m           ),
        .o_labels (m_m_6_8_l           ),
        .o_valid  (m_m_6_8_v           )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (2           ),
        .N1       (2           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (2           ),
        .LABEL_W1 (2           ),
        .N_OUT    (4           ),
        .CONC_W   (4           ),
        .N_U      (2           ),
        .TBL      (TBL_0           )
    )comb_0_4 (
        .clk        (clk        ),
        .i_valid    (m_m_0_2_v & m_m_2_4_v    ),
        .i_metrics  (m_m_0_2_m         ),
        .i_labels   (m_m_0_2_l         ),
        .i_metrics1 (m_m_2_4_m         ),
        .i_labels1  (m_m_2_4_l         ),
        .o_metrics  (m_c_0_4_m         ),
        .o_labels   (m_c_0_4_l         ),
        .o_valid    (m_c_0_4_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (2           ),
        .N1       (2           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (2           ),
        .LABEL_W1 (2           ),
        .N_OUT    (4           ),
        .CONC_W   (4           ),
        .N_U      (2           ),
        .TBL      (TBL_0           )
    )comb_4_8 (
        .clk        (clk        ),
        .i_valid    (m_m_4_6_v & m_m_6_8_v    ),
        .i_metrics  (m_m_4_6_m         ),
        .i_labels   (m_m_4_6_l         ),
        .i_metrics1 (m_m_6_8_m         ),
        .i_labels1  (m_m_6_8_l         ),
        .o_metrics  (m_c_4_8_m         ),
        .o_labels   (m_c_4_8_l         ),
        .o_valid    (m_c_4_8_v         )
    );

    top_comb#(
        .L        (L            ),
        .FSM      (TOP_FSM           ),
        .N        (4           ),
        .N1       (4           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (4           ),
        .N_OUT    (16           ),
        .CONC_W   (8           )
    )top_comb (
        .clk        (clk        ),
        .i_valid    (m_c_0_4_v & m_c_4_8_v    ),
        .i_metrics  (m_c_0_4_m         ),
        .i_labels   (m_c_0_4_l         ),
        .i_metrics1 (m_c_4_8_m         ),
        .i_labels1  (m_c_4_8_l         ),
        .o_metrics  (o_m         ),
        .o_labels   (o_l         ),
        .o_valid    (o_v         )
    );

endmodule

`timescale 1ns / 1ps