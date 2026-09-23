module mac (
    input  logic        clk,
    input  logic        rst,
    input  logic        enable,

    input  logic signed [7:0]  data_in,
    input  logic signed [7:0]  weight,

    output logic signed [31:0] acc_out
);

    always_ff @(posedge clk) begin

        if (rst) begin
            acc_out <= 32'sd0;
        end

        else if (enable) begin
            acc_out <= acc_out + (data_in * weight);
        end

    end

endmodule
