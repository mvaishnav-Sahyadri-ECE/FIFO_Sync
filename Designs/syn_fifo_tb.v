`timescale 1ns/1ps
module syn_fifo_tb;

    /* --------------------------
     * Clock generation: 100 MHz
     * --------------------------*/
    reg clk = 0;
    always #5 clk = ~clk;          // 5 ns half-period → 10 ns period

    /* --------------------------
     * Testbench stimulus signals
     * --------------------------*/
    reg         rst_n = 0;
    reg         wr_en = 0;
    reg         rd_en = 0;
    reg  [7:0]  data_in = 0;
    wire [7:0]  data_out;
    wire        full_o;
    wire        emty_o;

    /* --------------------------
     * DUT instantiation
     * --------------------------*/
    syn_fifo dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_in (data_in),
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .full_o  (full_o),
        .emty_o  (emty_o),
        .data_out(data_out)
    );

    /* --------------------------
     * Simple stimulus sequence
     * --------------------------*/
    integer i;

    initial begin
        /* 1. Release reset after 2 clock cycles */
        repeat (2) @(posedge clk);
        rst_n = 1;

        /* 2. Write eight bytes: 0-7 */
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            wr_en   <= 1;
            rd_en   <= 0;
            data_in <= i[7:0];
        end
        @(posedge clk) wr_en <= 0;   // stop writing

        /* 3. Read the eight bytes back */
        while (!emty_o) begin
            @(posedge clk);
            rd_en <= 1;
            wr_en <= 0;
            @(negedge clk);          // sample after data_out updates
            $display("READ 1: %0d  (time %0t)", data_out, $time);
        end
        @(posedge clk) rd_en <= 0;   // stop reading

        /* 4. Write four bytes: 100-103 */
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            wr_en   <= 1;
            data_in <= 8'd100 + i;
        end
        @(posedge clk) wr_en <= 0;

        /* 5. Read the four bytes back */
        while (!emty_o) begin
            @(posedge clk);
            rd_en <= 1;
            @(negedge clk);
            $display("READ 2: %0d  (time %0t)", data_out, $time);
        end
        @(posedge clk) rd_en <= 0;

        /* 6. Finish */
        #20 $finish;
    end
endmodule
