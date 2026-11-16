
// подумать над M_W+1 
module upward#(
    parameter M_W0,
    parameter M_W1,
    parameter N_COS0,
    parameter N_COS1,
    parameter M_W = ((M_W0 > M_W1) ? M_W0 : M_W1) + 1,
    parameter N_COS,
    parameter N_U,
    parameter logic [$clog2(N_COS0) + $clog2(N_COS1) - 1 : 0] TBL [0 : N_COS - 1][0 : N_U - 1]
)(
    input  logic                clk,
    input  logic                i_valid,
    input  logic [M_W0 - 1 : 0] i_ad0 [0 : N_COS0 - 1],
    input  logic [M_W1 - 1 : 0] i_ad1 [0 : N_COS1 - 1],
    
    output logic                o_valid,
    output logic [ M_W - 1 : 0] o_ad  [0 : N_COS - 1 ]
    );
    
    logic [M_W - 1 : 0] sums_comb [0 : N_COS - 1][0 : N_U - 1];
    logic [M_W - 1 : 0] sums_reg  [0 : N_COS - 1][0 : N_U - 1];
    logic [M_W - 1 : 0] ad_comb   [0 : N_COS - 1];
    logic [M_W - 1 : 0] ad_reg    [0 : N_COS - 1];
    logic [      1 : 0] valid_d;
    
    generate 
        for(genvar c = 0; c < N_COS; c++) begin
            for(genvar u = 0; u < N_U; u++) begin
                localparam logic [$clog2(N_COS0) - 1 : 0] L_IDX = TBL[c][u][$clog2(N_COS0) + $clog2(N_COS1) - 1 -: $clog2(N_COS0)];
                localparam logic [$clog2(N_COS1) - 1 : 0] R_IDX = TBL[c][u][                 $clog2(N_COS1) - 1 -: $clog2(N_COS1)];    
                
                assign sums_comb[c][u] = i_ad0[L_IDX] + i_ad1[R_IDX];
            end
        end
    endgenerate 
    
    always_ff @(posedge clk) begin
        for(int c = 0; c < N_COS; c++) begin
            for(int u = 0; u < N_U; u++) begin
                sums_reg[c][u] <= sums_comb[c][u];
            end
        end
    end
    
    generate 
        for(genvar c = 0; c < N_COS; c++) begin
           min_masked #(
                .W   (M_W),
                .N   (N_U)
            )u_min_ad (
                .i_mask('1         ),
                .i_vec (sums_reg[c]),
                .o_min (ad_comb[c] )
            );
        end
    endgenerate
    
    always_ff @(posedge clk) begin
        for(int c = 0; c < N_COS; c++) ad_reg[c] <= ad_comb[c]; 
        valid_d <= {valid_d[0], i_valid};
    end
    
    always_comb begin
        for(int c = 0; c < N_COS; c++) o_ad[c] = ad_reg[c];
        o_valid = valid_d[1]; 
    end
    
endmodule
