module nrzi_decoder
(
    input logic d,
    input logic clk,
    input logic n_rst,
    output logic d_orig,
    output logic d_edge
);
    logic q;

    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            q <= 1'b0;
            d_orig <= 1'b0;
            d_edge <= 1'b0;
        end else begin
            q <= d;
            d_orig <= ~(d ^ q);
            d_edge <= d ^ q;
        end
    end
endmodule