`timescale 1ns / 1ps

module exchange#(
    parameter M_W,
    parameter N_COS
)(
    input  logic               i_valid,
    input  logic [M_W - 1 : 0] i_ad0 [0 : N_COS - 1],
    input  logic [M_W - 1 : 0] i_ad1 [0 : N_COS - 1],
    
    output logic               o_valid,              
    output logic [M_W - 1 : 0] o_bd0 [0 : N_COS - 1],
    output logic [M_W - 1 : 0] o_bd1 [0 : N_COS - 1]
    );
    
    always_comb begin
        for(int c = 0; c < N_COS; c++) begin
            o_bd0[c] = i_ad1[c];
            o_bd1[c] = i_ad0[c];
        end
    end
    
    assign o_valid = i_valid;
    
endmodule
