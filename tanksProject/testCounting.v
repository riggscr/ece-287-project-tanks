module testCounting(input clk, input rst, input key, output reg sec);
reg [27:0] count;
reg [3:0]S;
reg [3:0]NS;


parameter 	START = 4'd0,
				INC = 4'd3,
				DONE = 4'd4,
				ERROR = 4'b1111;
				
				
always @ (posedge clk or negedge rst) begin
	if(rst == 1'b0)
		S <= START;
	else
		S <= NS;
end

always @ (*) begin
	case(S)
		START : begin
						if(key == 1'b0)
							NS = INC;
						else
							NS = START;
					end
		INC : begin
					if(key == 1'b0 & count < 28'd9000000)
						NS = INC;
					else if (key == 1'b0 & count == 28'd9000000)
						NS = DONE;
					else
						NS = START;
					end
		DONE: NS = INC;
	endcase
	
end

always @ (posedge clk or negedge rst) begin
	if(rst == 1'b0)
	begin
		count <= 28'd0;
		sec <= 1'd0;
	end
	else begin
		case(S)
			START: begin 
						count <= 28'd0;
						sec <= 1'd0;
						end
			INC: 
			begin
				count <= count + 1'b1;
				if(sec == 1'b1)
					sec <= 1'b0;
			end
			DONE: 
			begin
				sec <= 1'b1;
				count <= 28'd0;
				
			end
		endcase
	end
			
end
endmodule