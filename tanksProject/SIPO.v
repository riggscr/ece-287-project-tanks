module SIPO (
    input         din,         // serial data in
    input         clk,         // synchronized PS/2 clock
    input         clock_fpga,  // 50 MHz FPGA clock
    input         reset,       // active-low: fills register with ones
    output [10:0] dout,        // parallel data out
    output [3:0]  num          // counter for the number of shifts
);

    reg [10:0] s;
    reg [3:0]  count;

    // 8-sample glitch filter for PS/2 clock (160 ns stability window)
    reg [7:0]  clk_filter;
    reg        clk_debounced;
    reg        clk_debounced_prev;
    reg [15:0] timeout_cnt;

    wire clk_falling_edge = clk_debounced_prev && !clk_debounced;

    always @(posedge clock_fpga or negedge reset) begin
        if (reset == 1'b0) begin
            s                  <= 11'b111_1111_1111;
            count              <= 4'd0;
            clk_filter         <= 8'hFF;
            clk_debounced      <= 1'b1;
            clk_debounced_prev <= 1'b1;
            timeout_cnt        <= 16'd0;
        end
        else begin
            // Filter ringing on PS/2 clock edges
            clk_filter         <= {clk_filter[6:0], clk};
            clk_debounced_prev <= clk_debounced;
            if (clk_filter == 8'hFF)
                clk_debounced <= 1'b1;
            else if (clk_filter == 8'h00)
                clk_debounced <= 1'b0;

            // Shift one bit on each clean falling edge of PS/2 clock
            if (clk_falling_edge) begin
                timeout_cnt <= 16'd0;
                s           <= {din, s[10:1]};

                if (count < 4'd11)
                    count <= count + 4'd1;
                else
                    count <= 4'd1;
            end
            else if (count != 4'd0 && count != 4'd11) begin
                // Auto-resync if a mid-frame byte stalls > 500 us
                if (timeout_cnt >= 16'd25000) begin
                    count       <= 4'd0;
                    timeout_cnt <= 16'd0;
                end
                else begin
                    timeout_cnt <= timeout_cnt + 16'd1;
                end
            end
        end
    end

    assign dout = s;
    assign num  = count;

endmodule


/*module SIPO (
			input 			din, 			//serial data in
			input 			clk, 			//clock signal
			input 			reset, 		//fills register with one's
			input				clock_fpga,  //clock of fpga @ 50 Mhz
			output [10:0]	dout, 		//parallel data out
			output [3:0] 	num			//counter for the number of shifts
			);

///////Internal registers/////////
reg [10:0] data_out;
reg [10:0]s;
reg [3:0] count;

always @ (negedge clk or negedge reset)
	if (reset == 1'b0) 
		begin
			s <= 11'b111_1111_1111;
			count <= 4'd0;
		end
	else
		begin
			s[10] <= din;
			s[9] <= s[10];
			s[8] <= s[9];
			s[7] <= s[8];
			s[6] <= s[7];
			s[5] <= s[6];
			s[4] <= s[5];
			s[3] <= s[4];
			s[2] <= s[3];
			s[1] <= s[2];
			s[0] <= s[1];
			///we count the number of times the register shifts until a full new code is in the register
			if (count < 4'd11)
				count <= count + 1'b1;
			else 
				count <= 4'd1;
		end

assign dout = s;
assign num = count;

endmodule*/