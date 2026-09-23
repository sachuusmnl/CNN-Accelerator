`timescale 1ns/1ps

module convolution_tb;

    localparam int LATENCY = 9;     // edges from start-sample to done

    logic clk = 0, rst = 1, start = 0;
    logic signed [7:0]  data   [0:8];
    logic signed [7:0]  weight [0:8];
    logic signed [31:0] result;
    logic               done;

    convolution dut (.*);

    always #5 clk = ~clk;

    int errors = 0;

    function automatic int expected();
        int s = 0;
        for (int i = 0; i < 9; i++) s += data[i] * weight[i];
        return s;
    endfunction

    task automatic fail(string msg);
        errors++;
        $display("[%0t] FAIL: %s", $time, msg);
    endtask

    // done must never be high two cycles in a row
    logic done_q = 0;
    always @(posedge clk) begin
        if (done && done_q) fail("done held for more than one cycle");
        done_q <= done;
    end

    // Inputs are driven on negedge to avoid races with the DUT.
    // extra_start_at >= 0 pulses start again that many cycles into the run
    // (must be ignored).
    task automatic run_one(string name, int extra_start_at = -1);
        int exp = expected();
        int n   = 0;

        @(negedge clk); start = 1;
        @(negedge clk); start = 0;                // edge 0 sampled start

        while (!done && n < 30) begin
            if (n == extra_start_at) start = 1;
            @(negedge clk);
            start = 0;
            n++;
        end

        if (!done)                fail({name, ": timeout waiting for done"});
        else begin
            if (n + 1 != LATENCY) fail($sformatf("%s: latency %0d, expected %0d", name, n + 1, LATENCY));
            if (result !== exp)   fail($sformatf("%s: result %0d, expected %0d", name, result, exp));
            else                  $display("PASS %-22s result = %0d", name, result);
        end

        @(negedge clk);
        if (done) fail({name, ": done did not drop after one cycle"});
    endtask

    task automatic randomize_inputs();
        for (int i = 0; i < 9; i++) begin
            data[i]   = $urandom_range(0, 255);
            weight[i] = $urandom_range(0, 255);
        end
    endtask

    task automatic fill(logic signed [7:0] d, logic signed [7:0] w);
        for (int i = 0; i < 9; i++) begin data[i] = d; weight[i] = w; end
    endtask

    // Global watchdog
    initial begin
        #5_000_000;
        $display("FAIL: global timeout");
        $finish;
    end

    initial begin
        $dumpfile("convolution.vcd");
        $dumpvars(0, convolution_tb);

        fill(0, 0);
        repeat (3) @(negedge clk);
        rst = 0;

        // 1. Nothing may happen without start
        repeat (30) begin
            @(negedge clk);
            if (done) fail("done asserted without start");
        end

        // 2. Original directed test (expect -6)
        data[0]=1;  data[1]=2;  data[2]=3;
        data[3]=5;  data[4]=6;  data[5]=7;
        data[6]=9;  data[7]=10; data[8]=11;
        weight[0]=1; weight[1]=0; weight[2]=-1;
        weight[3]=1; weight[4]=0; weight[5]=-1;
        weight[6]=1; weight[7]=0; weight[8]=-1;
        run_one("directed (-6)");

        // 3. Extremes
        fill(-128, -128); run_one("all -128 * -128");
        fill(-128,  127); run_one("all -128 *  127");
        fill( 127,  127); run_one("all  127 *  127");
        fill(   0,    0); run_one("all zero");

        // 4. start pulsed while busy must be ignored
        randomize_inputs();
        run_one("start while busy", 4);

        // 5. Reset mid-run: no done, then clean recovery
        randomize_inputs();
        @(negedge clk); start = 1;
        @(negedge clk); start = 0;
        repeat (3) @(negedge clk);
        rst = 1;
        repeat (12) begin
            @(negedge clk);
            if (done) fail("done asserted after reset mid-run");
        end
        rst = 0;
        run_one("after mid-run reset");

        // 6. Random back-to-back
        for (int t = 0; t < 200; t++) begin
            randomize_inputs();
            run_one($sformatf("random %0d", t));
        end

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
