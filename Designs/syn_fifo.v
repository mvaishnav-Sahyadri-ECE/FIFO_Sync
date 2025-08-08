`timescale 1ns/1ps
module syn_fifo (
    input              clk,
    input              rst_n,           // active-low reset
    input      [7:0]   data_in,
    input              wr_en,
    input              rd_en,
    output             full_o,
    output             emty_o,
    output reg [7:0]   data_out
);
    // -------------------------------------------------
    // FIFO PARAMETERS
    // -------------------------------------------------
    parameter DEPTH = 8;                // must be 8 for pointer widths below

    // -------------------------------------------------
    // STORAGE AND POINTERS
    // -------------------------------------------------
    reg [7:0] mem [0:DEPTH-1];          // 8-entry RAM
    reg [2:0] wr_ptr;                   // addresses 0-7
    reg [2:0] rd_ptr;                   // addresses 0-7
    reg [3:0] count;                    // 0-8 (needs 4 bits)

    // -------------------------------------------------
    // STATUS FLAGS
    // -------------------------------------------------
    assign full_o = (count == DEPTH);
    assign emty_o = (count == 0);

    // -------------------------------------------------
    // WRITE LOGIC
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 3'd0;
        end else if (wr_en && !full_o) begin
            mem[wr_ptr] <= data_in;
            wr_ptr      <= wr_ptr + 3'd1;
        end
    end

    // -------------------------------------------------
    // READ LOGIC
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr   <= 3'd0;
            data_out <= 8'd0;
        end else if (rd_en && !emty_o) begin
            data_out <= mem[rd_ptr];
            rd_ptr   <= rd_ptr + 3'd1;
        end
    end

    // -------------------------------------------------
    // COUNT UPDATE (for full/empty flags)
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
        end else begin
            case ({wr_en && !full_o, rd_en && !emty_o})
                2'b10: count <= count + 4'd1;   // write only
                2'b01: count <= count - 4'd1;   // read only
                default: count <= count;        // simultaneous or idle
            endcase
        end
    end
endmodule
