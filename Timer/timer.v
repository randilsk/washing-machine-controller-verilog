`timescale 1ns/1ps

module timer(
    input clk,
    input reset,
    input start,
    input [31:0] duration,
    output reg done
);

    reg [31:0] counter;
    reg active;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            active <= 0;
            done <= 0;
        end else begin
            done <= 0;
            
            if (start) begin
                counter <= duration;
                active <= 1;
            end else if (active) begin
                if (counter > 0) begin
                    counter <= counter - 1;
                end else begin
                    active <= 0;
                    done <= 1;
                end
            end
        end
    end

endmodule