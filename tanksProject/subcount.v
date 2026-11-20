module subcount(input [3:0] KEY, input clk, input rst, output wire [3:0] dir);

testCounting my_down(clk, rst, KEY[1], dir[0]);
testCounting my_up(clk, rst, KEY[2], dir[1]);
testCounting my_left(clk, rst, KEY[3], dir[2]);
testCounting my_right(clk, rst, KEY[0], dir[3]);

endmodule