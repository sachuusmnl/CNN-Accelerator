// 3x3 dot-product engine (one output pixel of a 3x3 convolution).
// One multiplier, one accumulator, 9 cycles per result.
//
//   start  : pulse for 1 cycle while idle to begin (ignored while busy)
//   done   : 1-cycle pulse; `result` is valid in that cycle and holds
//            until the next start
//   Latency: `done` rises 9 clock edges after the edge that samples `start`
//
// Assumption: data[] and weight[] are held stable from the `start` cycle
// until `done` (they are read live, not copied, to save 144 flops).
module convolution #(
    parameter int N     = 9,                    // number of taps
    parameter int ACC_W = 16 + $clog2(N) + 1    // 8x8 products (16b) summed N times
)(
    input  logic               clk,
    input  logic               rst,             // synchronous, active high
    input  logic               start,

    input  logic signed [7:0]  data   [0:N-1],
    input  logic signed [7:0]  weight [0:N-1],

    output logic signed [31:0] result,
    output logic               done
);

    localparam int CNT_W = $clog2(N);

    logic                    busy;
    logic [CNT_W-1:0]        count;             // index of the tap being multiplied
    logic signed [ACC_W-1:0] acc;

    // In the start cycle (idle) tap 0 is multiplied and the accumulator is
    // seeded with it, so no separate "clear" cycle is needed.
    logic [CNT_W-1:0]        idx;
    logic signed [15:0]      prod;
    logic signed [ACC_W-1:0] base;

    assign idx  = busy ? count : '0;
    assign prod = data[idx] * weight[idx];
    assign base = busy ? acc : '0;

    always_ff @(posedge clk) begin
        if (rst) begin
            busy  <= 1'b0;
            count <= '0;
            acc   <= '0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                if (start) begin                // tap 0
                    acc   <= base + prod;
                    count <= CNT_W'(1);
                    busy  <= 1'b1;
                end
            end else begin                      // taps 1 .. N-1
                acc <= base + prod;
                if (count == CNT_W'(N-1)) begin
                    busy  <= 1'b0;
                    count <= '0;
                    done  <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

    assign result = acc;                        // sign-extends to 32 bits

endmodule
