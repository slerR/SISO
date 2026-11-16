`timescale 1ns / 1ps

module axi_fifo_no_bram#(
    parameter DEPTH     = 16,
    parameter DATA_W    = 16,
    parameter FIFO_TYPE = "auto" // "auto", "distributed", "registers"
)(
    input logic                   clk,
    input logic                   rst,
    
    input  logic [DATA_W - 1 : 0] s_axis_tdata,
    input  logic                  s_axis_tvalid, 
    output logic                  s_axis_tready, // !full
    
    output logic [DATA_W - 1 : 0] m_axis_tdata,
    output logic                  m_axis_tvalid, 
    input  logic                  m_axis_tready // !empty
    );
    
    (* ram_style = FIFO_TYPE *) logic [DATA_W - 1 : 0] mem [0 : DEPTH - 1];
    
    logic [$clog2(DEPTH) - 1 : 0] wrt_ptr;
    logic [$clog2(DEPTH) - 1 : 0] rd_ptr;
    logic                         wrt_par;
    logic                         rd_par; 
    logic                         full;
    logic                         empty;
    
    // write procces
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            wrt_ptr <= '0;
            wrt_par <= 0;
        end else begin
            if(s_axis_tvalid & s_axis_tready) begin
                mem[wrt_ptr] <= s_axis_tdata;
                if(wrt_ptr == DEPTH - 1) begin
                    wrt_ptr <= '0;
                    wrt_par <= !wrt_par;
                end else begin
                    wrt_ptr <= wrt_ptr + 1;
                end               
            end
        end
    end
    
    // read proc
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            rd_ptr <= '0;
            rd_par <= 0;
        end else begin
            if(m_axis_tvalid & m_axis_tready) begin
                if(rd_ptr == DEPTH - 1) begin
                    rd_ptr <= '0;
                    rd_par <= !rd_par;
                end else begin
                    rd_ptr <= rd_ptr + 1;
                end               
            end
        end
    end
    
    assign m_axis_tdata = mem[rd_ptr];
    
    assign empty = (wrt_ptr == rd_ptr) && (wrt_par == rd_par);
    assign full  = (wrt_ptr == rd_ptr) && (wrt_par != rd_par);
    
    assign s_axis_tready = !full;
    assign m_axis_tvalid = !empty;

    
endmodule
