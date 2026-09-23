`timescale 1ns/1ps

module convolution_tb;

    logic clk;
    logic rst;
    logic start;

    logic signed [7:0] data [0:8];
    logic signed [7:0] weight [0:8];

    logic signed [31:0] result;
    logic done;

    convolution dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data(data),
        .weight(weight),
        .result(result),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/convolution.vcd");
        $dumpvars(0, convolution_tb);


        clk   = 0;
        rst   = 1;
        start = 0;

        // 3x3 input
        data[0] = 1;
        data[1] = 2;
        data[2] = 3;

        data[3] = 5;
        data[4] = 6;
        data[5] = 7;

        data[6] = 9;
        data[7] = 10;
        data[8] = 11;

        // 3x3 kernel
        weight[0] = 1;
        weight[1] = 0;
        weight[2] = -1;

        weight[3] = 1;
        weight[4] = 0;
        weight[5] = -1;

        weight[6] = 1;
        weight[7] = 0;
        weight[8] = -1;

        // Release reset
        #10;
        rst = 0;

        // Start convolution
        #10;
        start = 1;

        #10;
        start = 0;

        // Wait for completion
        wait(done);

        $display("Convolution result = %d", result);

        #10;
        $finish;

    end

endmodule
