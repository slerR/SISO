`timescale 1ns / 1ps

module top_8_4#(
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
         '{4'b0000, 4'b1011},   // a=0
         '{4'b0101, 4'b1110},   // a=1
         '{4'b0110, 4'b1101},   // a=2
         '{4'b0011, 4'b1000}},  // a=3
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL_B_04_48 [0 : N_COS - 1][0 : K_B - 1] = '{
         '{4'b0000, 4'b1011},   // b=0
         '{4'b0101, 4'b1110},   // b=1
         '{4'b0110, 4'b1101},   // b=2
         '{4'b0011, 4'b1000}},  // b=3  
    localparam T_INIT          = 2 + $clog2(L),
    localparam T_UP            = 2,   
    localparam T_DOWN          = 1,
    localparam T_FORM          = 2,    
    localparam FIFO_AB_DEPTH   = T_UP + 1,   
    localparam FIFO_ABIB_DEPTH = T_UP + T_DOWN + 1         
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         i_valid,
    input  logic signed [LLR_W - 1 : 0]  i_llr [0 : N - 1],
    
    output logic                         o_valid,
    output logic signed [(M_WL + 3) : 0] o_llr [0 : N - 1] // 1 upward layer, 1 downward layer, 1 form_llr
    );
    
    logic [       3 : 0] leaf_valid;
    logic [M_WL - 1 : 0] leaf_ad   [0 : 3][0 : N_COS - 1];
    logic [M_WL - 1 : 0] leaf_adib [0 : 3][0 : N_COS - 1][0 : L - 1][0 : 1];
    
    generate
        for(genvar i = 0; i < 4; i++) begin
            init_leaf#(
                .LLR_W  (LLR_W  ),
                .L      (L      ),
                .M_W    (M_WL   ),
                .N_COS  (N_COS  ),
                .N_WORDS(N_WORDS),
                .LXY    (LXY    )
            )leaf (
                .clk    (clk            ),
                .i_valid(i_valid        ),
                .i_llr  (i_llr[2*i +: 2]),
                .o_valid(leaf_valid[i]  ),
                .o_ad   (leaf_ad[i]     ),
                .o_adib (leaf_adib[i]   )
            );           
        end
    endgenerate 
    
    logic [             1 : 0] upward_valid;
    logic [(M_WL + 1) - 1 : 0] upward_ad [0 : 1][0 : N_COS - 1];
    
    
    generate
        for(genvar i = 0; i < 2; i++) begin
            upward#(
                .M_W0  (M_WL        ),
                .M_W1  (M_WL        ),
                .N_COS0(N_COS       ),
                .N_COS1(N_COS       ),
                .M_W   (M_WL+1      ),
                .N_COS (N_COS       ),
                .N_U   (N_U         ),
                .TBL   (TBL_UP_04_48)
            )upward (
                .clk    (clk                              ),
                .i_valid(leaf_valid[2*i]&leaf_valid[2*i+1]),
                .i_ad0  (leaf_ad[2*i]                     ),
                .i_ad1  (leaf_ad[2*i+1]                   ),
                .o_valid(upward_valid[i]                  ),
                .o_ad   (upward_ad[i]                     )
            );
        end
    endgenerate 
    
    logic                      ex_valid;
    logic [(M_WL + 1) - 1 : 0] ex_bd [0 : 1][0 : N_COS - 1];
    
    exchange#(
        .M_W  (M_WL+1),
        .N_COS(N_COS )
    )exchange (
        .i_valid(upward_valid[0]&upward_valid[1]),
        .i_ad0  (upward_ad[0]                   ),
        .i_ad1  (upward_ad[1]                   ),  
        .o_valid(ex_valid                       ),
        .o_bd0  (ex_bd[0]                       ),
        .o_bd1  (ex_bd[1]                       )
    );
    
    logic [    M_WL*N_COS - 1 : 0] leaf_ad_packed   [0 : 3];  
    logic [    M_WL*N_COS - 1 : 0] leaf_ad_packed_d [0 : 3];  
    logic [                 3 : 0] fifo_ad_valid;
    
    always_comb begin
        for(int i = 0; i < 4; i++) begin
            for(int c = 0; c < N_COS; c++) begin
                leaf_ad_packed[i][c*M_WL +: M_WL] = leaf_ad[i][c];
            end
        end
    end
    
    generate 
        for(genvar i = 0; i < 4; i++) begin
            axi_fifo_no_bram #(
                .DEPTH (FIFO_AB_DEPTH),
                .DATA_W(M_WL*N_COS   )
            )fifo_ad (
                .clk          (clk                ),
                .rst          (rst                ),
                .s_axis_tdata (leaf_ad_packed[i]  ),
                .s_axis_tvalid(leaf_valid[i]      ),
                .s_axis_tready(                   ),
                .m_axis_tdata (leaf_ad_packed_d[i]),
                .m_axis_tvalid(fifo_ad_valid[i]   ),
                .m_axis_tready(ex_valid           ) 
            );
        end
    endgenerate
    
    logic [M_WL - 1 : 0] leaf_ad_d   [0 : 3][0 : N_COS - 1];

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            for (int c = 0; c < N_COS; c++) begin
                leaf_ad_d[i][c] = leaf_ad_packed_d[i][c*M_WL +: M_WL];
            end
        end
    end
    
    logic [             1 : 0] downward_valid;
    logic [(M_WL + 2) - 1 : 0] down_bd [0 : 3][0 : N_COS - 1];
    
    generate
        for(genvar i = 0; i < 2; i++) begin
            downward#(
                .M_W0  (M_WL       ),
                .M_W1  (M_WL       ),
                .M_WB  (M_WL+1     ),
                .M_WO  (M_WL+2     ),
                .N_COS0(N_COS      ),
                .N_COS1(N_COS      ),
                .N_COS (N_COS      ),
                .K_A   (K_A        ),
                .K_B   (K_B        ),
                .TBL_A (TBL_A_04_48),
                .TBL_B (TBL_B_04_48)
            )downward (
                .clk    (clk              ),
                .i_valid(ex_valid         ),
                .i_bd   (ex_bd[i]         ),
                .i_ad0  (leaf_ad_d[2*i]   ),
                .i_ad1  (leaf_ad_d[2*i+1] ),
                .o_valid(downward_valid[i]),
                .o_bd0  (down_bd[2*i]     ),
                .o_bd1  (down_bd[2*i+1]   )
            );
        end
    endgenerate
    
    logic [M_WL*N_COS*L*2 - 1 : 0] leaf_adib_packed  [0 : 3];
    logic [M_WL*N_COS*L*2 - 1 : 0] leaf_adib_packed_d[0 : 3];
    logic [                 3 : 0] fifo_adib_valid;
    
    always_comb begin
        for(int i = 0; i < 4; i++) begin
            for(int c = 0; c < N_COS; c++) begin
                for(int l = 0; l < L; l++) begin
                    for(int b = 0; b < 2; b++) begin
                        leaf_adib_packed[i][((c*L + l)*2 + b)*M_WL +: M_WL] = leaf_adib[i][c][l][b];    
                    end     
                end
            end
        end
    end
    
    generate 
        for(genvar i = 0; i < 4; i++) begin        
            axi_fifo_no_bram #(
                .DEPTH (FIFO_ABIB_DEPTH),
                .DATA_W(M_WL*N_COS*L*2 )
            )fifo_adib (
                .clk          (clk                  ),
                .rst          (rst                  ),
                .s_axis_tdata (leaf_adib_packed[i]  ),
                .s_axis_tvalid(leaf_valid[i]        ),
                .s_axis_tready(                     ),
                .m_axis_tdata (leaf_adib_packed_d[i]),
                .m_axis_tvalid(fifo_adib_valid[i]   ),
                .m_axis_tready(downward_valid[i/2]  )
            );
        end
    endgenerate
    
    logic [M_WL-1:0] leaf_adib_d [0:3][0:N_COS-1][0:L-1][0:1];
    
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            for (int c = 0; c < N_COS; c++) begin
                for (int l = 0; l < L; l++) begin
                    for (int b = 0; b < 2; b++) begin
                        leaf_adib_d[i][c][l][b] = leaf_adib_packed_d[i][((c*L + l)*2 + b)*M_WL +: M_WL];
                    end
                end
            end
        end
    end 
    
    logic [3 : 0] form_valid;
    
    generate 
        for(genvar i = 0; i < 4; i++) begin
            form_llr#(
                .M_W_ADIB(M_WL  ),
                .M_W_BD  (M_WL+2),
                .L       (L     ),
                .N_COS   (N_COS ),
                .M_W     (M_WL+3)
            )form_llr (
                .clk    (clk                ),
                .i_valid(downward_valid[i/2]),
                .i_bd   (down_bd[i]         ),
                .i_adib (leaf_adib_d[i]     ),
                .o_valid(form_valid[i]      ),
                .o_llr  (o_llr[2*i +: 2]    )
            );
        end
    endgenerate
    
    assign o_valid = &form_valid;
              
endmodule
