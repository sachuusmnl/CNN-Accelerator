`timescale 1ns/1ps

module mac_tb;

    logic clk = 0, rst = 1, enable = 0;
    logic signed [7:0]  data_in = 0, weight = 0;
    logic signed [31:0] acc_out;

    mac dut (.*);

    always #5 clk = ~clk;

    int model  = 0;
    int errors = 0;

    // Drive on negedge, check just before the next negedge (after the posedge).
    task automatic step(logic r, logic en, int d, int w);
        rst = r; enable = en; data_in = d; weight = w;
        @(posedge clk);
        if (r)       model = 0;
        else if (en) model = model + d * w;
        #1;
        if (acc_out !== model) begin
            errors++;
            $display("[%0t] FAIL: acc_out=%0d expected=%0d", $time, acc_out, model);
        end
        @(negedge clk);
    endtask

    initial begin
        $dumpfile("mac.vcd");
        $dumpvars(0, mac_tb);

        @(negedge clk);
        step(1, 0, 0, 0);          // reset
        step(0, 1, 2, 3);          //  6
        step(0, 1, 4, 5);          // 26
        step(0, 1, 3, 2);          // 32
        step(0, 0, 9, 9);          // enable low: must hold 32
        step(0, 1, -5, 7);         // negative * positive
        step(0, 1, -128, -128);    // most negative * most negative
        step(0, 1, 127, -128);
        step(1, 1, 7, 7);          // reset beats enable
        step(0, 1, 1, 1);

        for (int i = 0; i < 500; i++)
            step(($urandom % 50) == 0, $urandom_range(0, 1),
                 $urandom_range(0, 255) - 128, $urandom_range(0, 255) - 128);

        if (errors == 0) $display("ALL TESTS PASSED (final acc = %0d)", acc_out);
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
