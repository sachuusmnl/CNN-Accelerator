`timescale 1ns/1ps

module mac_tb;

    logic clk;
    logic rst;
    logic enable;

    logic signed [7:0] data_in;
    logic signed [7:0] weight;

    logic signed [31:0] acc_out;

    // Instantiate MAC
    mac dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .weight(weight),
        .acc_out(acc_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        // Initial values
        clk = 0;
        rst = 1;
        enable = 0;
        data_in = 0;
        weight = 0;

        // Reset
        #10;
        rst = 0;

        // First MAC: 2 × 3
        data_in = 2;
        weight = 3;
        enable = 1;

        #10;

        // Second MAC: 4 × 5
        data_in = 4;
        weight = 5;

        #10;

        // Third MAC: 3 × 2
        data_in = 3;
        weight = 2;

        #10;

        enable = 0;

        #10;

        $display("Final accumulator = %d", acc_out);

        $finish;

    end

endmodule
