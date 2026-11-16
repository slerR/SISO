`timescale 1ns / 1ps

module min2#(
    parameter W = 8
)(
    input  logic [W - 1 : 0] i_x,
    input  logic [W - 1 : 0] i_y,
    output logic [W - 1 : 0] o_min
);
    assign o_min = (i_x < i_y) ? i_x : i_y;
endmodule