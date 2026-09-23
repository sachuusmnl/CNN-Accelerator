module convolution (
    input  logic clk,
    input  logic rst,
    input  logic start,

    input  logic signed [7:0] data [0:8],
    input  logic signed [7:0] weight [0:8],

    output logic signed [31:0] result,
    output logic done
);

    logic [3:0] count;
    logic signed [31:0] accumulator;

    always_ff @(posedge clk) begin

        if (rst) begin
            count       <= 0;
            accumulator <= 0;
            result      <= 0;
            done        <= 0;
        end

        else begin
            done <= 0;

            if (start) begin
                count       <= 0;
                accumulator <= 0;
            end

            else if (count < 9) begin
                accumulator <= accumulator +
                               (data[count] * weight[count]);

                count <= count + 1;
            end

            else begin
                result <= accumulator;
                done   <= 1;
            end
        end
    end

endmodule
