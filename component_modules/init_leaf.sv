module init_leaf#(
    parameter LLR_W,                  // input llr's width
    parameter L,                      // section size
    parameter M_W = LLR_W + $clog2(L),// metric width
    parameter N_COS,                  // number of cosseets in Lxy (decomposition)
    parameter N_WORDS,                // number of words in each cosset
    parameter logic [L - 1 : 0] LXY [0 : N_COS - 1][0 : N_WORDS - 1]
)( 
    input logic                        clk,
    input logic                        i_valid,
    input logic signed [LLR_W - 1 : 0] i_llr [0 : L - 1     ],                  // input llr decisions
    
    output logic                       o_valid,
    output logic       [  M_W - 1 : 0] o_ad   [0 : N_COS - 1],                  // best (min) metric of the cosset
    output logic       [  M_W - 1 : 0] o_adib [0 : N_COS - 1][0 : L - 1][0 : 1] // best (min) metric in the cosset... 
    //...with fix bit
);

    localparam logic signed MIN_LLR = 1 << (LLR_W - 1);
    localparam logic        MAX_LLR = $unsigned(MIN_LLR - 1);
    localparam int          DELAY   = 2 + $clog2(L);
    
    logic [LLR_W - 1 : 0] abs_llr  [0 : L - 1    ];
    logic [    L - 1 : 0] sgn_llr;
    logic [    L - 1 : 0] mismatch [0 : N_COS - 1][0 : N_WORDS - 1];
    
    // first stage: take sign of the i_llr, calculate abs value and bit mismatch
    always_comb begin
        for(int i = 0; i < L; i++) begin
            sgn_llr[i] = i_llr[i][LLR_W - 1];
        end
    end
    
    always_ff @(posedge clk) begin
        for(int i = 0; i < L; i++) begin
            if(i_llr[i] == MIN_LLR) begin
                abs_llr[i] <= MAX_LLR;    
            end else if(sgn_llr[i]) begin
                abs_llr[i] <= $unsigned(-i_llr[i]);   
            end else begin
                abs_llr[i] <= $unsigned(i_llr[i]); 
            end
        end   
    end
    
    always_ff @(posedge clk) begin
        for(int c = 0; c < N_COS; c++) begin
            for(int w = 0; w < N_WORDS; w++) begin
                for(int b = 0; b < L; b++) begin
                    mismatch[c][w][b] <= LXY[c][w][L - 1 - b] ^ sgn_llr[b];  
                end
            end
        end
    end
    
    // second stage: calculate metrics
    logic [LLR_W - 1 : 0] summands [0 : N_COS - 1][0 : N_WORDS - 1][0 : L - 1];
    logic [  M_W - 1 : 0] sums     [0 : N_COS - 1][0 : N_WORDS - 1];
    
    always_comb begin
        for(int c = 0; c < N_COS; c++) begin
            for(int w = 0; w < N_WORDS; w++) begin
                for(int b = 0; b < L; b++) begin
                    summands[c][w][b] = (mismatch[c][w][b]) ? abs_llr[b] : '0;  
                end
            end
        end
    end
    
    generate 
        for(genvar c = 0; c < N_COS; c++) begin 
            for(genvar w = 0; w < N_WORDS; w++) begin 
                n_adder#(
                    .N  (L    ),
                    .I_W(LLR_W),
                    .O_W(M_W  )
                )n_adder ( 
                    .clk   (clk           ),
                    .i_data(summands[c][w]),
                    .o_data(sums[c][w]    )
                ); 
            end    
        end
    endgenerate
    
    // third stage: find best metrics
    logic [N_WORDS - 1 : 0] mask_ab [0 : N_COS - 1][0 : L - 1][0 : 1];
    logic [  DELAY - 1 : 0] valid_d;
    
    always_comb begin
        for(int c = 0; c < N_COS; c++) begin
            for(int i = 0; i < L; i++) begin
                for(int b = 0; b < 2; b++) begin
                    for(int w = 0; w < N_WORDS; w++) begin : g_mask_w
                        mask_ab[c][i][b][w] = (LXY[c][w][L-1-i] == b);
                    end
                end
            end
        end
    end
    
    generate
        for (genvar c = 0; c < N_COS; c++) begin
            min_masked #(
                .W   (M_W   ),
                .N   (N_WORDS)
            )u_min_ad (
                .i_mask(     '1),
                .i_vec (sums[c]),
                .o_min (o_ad[c])
            );

            for (genvar i = 0; i < L; i++) begin
                for (genvar b = 0; b < 2; b++) begin
                    min_masked#(
                        .W   (M_W             ),
                        .N   (N_WORDS         )
                    )u_min_ab (
                        .i_mask(mask_ab[c][i][b]),
                        .i_vec(sums[c]          ),
                        .o_min(o_adib[c][i][b]  )
                    );
                end
            end
        end
    endgenerate
          
    always_ff @(posedge clk) begin
        valid_d <= {valid_d[DELAY - 2 : 0], i_valid};  // мб поставить запрет на SRL 
    end
    
    assign o_valid = valid_d[DELAY - 1];
    
endmodule