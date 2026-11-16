`timescale 1ns / 1ps

// подумать над M_W0 + 1
module downward#(
    parameter M_W0,
    parameter M_W1,
    parameter M_WB,
    parameter N_COS0,
    parameter N_COS1,
    parameter N_COS,
    parameter K_A,
    parameter K_B,
    parameter M_W  = (M_W0 > M_W1) ? M_W0 : M_W1,
    parameter M_WO = ((M_W > M_WB) ? M_W : M_WB) + 1,
    parameter LV_P = ($clog2(N_COS)  < 1) ? 1 : $clog2(N_COS),
    parameter LA_P = ($clog2(N_COS0) < 1) ? 1 : $clog2(N_COS0),
    parameter LB_P = ($clog2(N_COS1) < 1) ? 1 : $clog2(N_COS1),
    // TBL_A[a][k] = {v, b}
    parameter logic [LV_P + LB_P - 1 : 0] TBL_A [0:N_COS0-1][0:K_A-1],
    // TBL_B[b][k] = {v, a}
    parameter logic [LV_P + LA_P - 1 : 0] TBL_B [0:N_COS1-1][0:K_B-1]
)(
    input  logic                    clk,
    input  logic                    i_valid,
    input  logic [M_WB - 1 : 0]     i_bd  [0 : N_COS - 1 ],
    input  logic [M_W0 - 1 : 0]     i_ad0 [0 : N_COS0 - 1],
    input  logic [M_W1 - 1 : 0]     i_ad1 [0 : N_COS1 - 1],

    output logic                    o_valid,
    output logic [M_WO - 1 : 0]     o_bd0 [0 : N_COS0 - 1],
    output logic [M_WO - 1 : 0]     o_bd1 [0 : N_COS1 - 1]
);

    localparam LV = LV_P;
    localparam LA = LA_P;
    localparam LB = LB_P;

    logic [M_WO - 1 : 0] bd0_comb [0 : N_COS0 - 1][0 : K_A - 1];
    logic [M_WO - 1 : 0] bd0_min  [0 : N_COS0 - 1];
    logic [M_WO - 1 : 0] bd1_comb [0 : N_COS1 - 1][0 : K_B - 1];
    logic [M_WO - 1 : 0] bd1_min  [0 : N_COS1 - 1];

    generate
        for (genvar a = 0; a < N_COS0; a++) begin
            for (genvar k = 0; k < K_A; k++) begin
                localparam logic [LV - 1 : 0] V = TBL_A[a][k][LV + LB - 1 -: LV];
                localparam logic [LB - 1 : 0] B = TBL_A[a][k][  LB - 1    -: LB];
                assign bd0_comb[a][k] = i_bd[V] + i_ad1[B];
            end
            min_masked #(
                .W(M_WO),
                .N(K_A ) 
            )u_min_a (
                .i_mask('1         ),
                .i_vec (bd0_comb[a]),
                .o_min (bd0_min[a] )
            );
        end

        for (genvar b = 0; b < N_COS1; b++) begin 
            for (genvar k = 0; k < K_B; k++) begin 
                localparam logic [LV - 1 : 0] V = TBL_B[b][k][LV + LA - 1 -: LV];
                localparam logic [LA - 1 : 0] A = TBL_B[b][k][  LA - 1    -: LA];
                assign bd1_comb[b][k] = i_bd[V] + i_ad0[A];
            end
            min_masked #(
                .W(M_WO), 
                .N(K_B )
            )u_min_b (
                .i_mask('1         ),
                .i_vec (bd1_comb[b]),
                .o_min (bd1_min[b] )
            );
        end
    endgenerate
    
    always_ff @(posedge clk) begin
        for(int a = 0; a < N_COS0; a++) begin
            o_bd0[a] <=  bd0_min[a];  
        end
        for(int b = 0; b < N_COS1; b++) begin
            o_bd1[b] <=  bd1_min[b];  
        end
        
        o_valid <= i_valid;
    end
    
endmodule