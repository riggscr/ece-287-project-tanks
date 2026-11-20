module btankmap(input [9:0] drawX, input [9:0] drawY, input [3:0] direction, output reg o); 

always @ (*)
begin

	//9*10
	if(direction == 4'd3) //right
	begin
		o = ((drawX < 10'd7 & drawY == 10'd0) | 
		(drawX < 10'd7 & drawY == 10'd1) |
		(drawX > 10'd1 & drawX < 10'd6 & drawY == 10'd2) | 
		(drawX > 10'd1 & drawX < 10'd6 & drawY == 10'd3) | 
		(drawX > 10'd1 & drawX < 10'd11 & drawY == 10'd4) | 
		(drawX > 10'd1 & drawX < 10'd6 & drawY == 10'd5) | 
		(drawX > 10'd1 & drawX < 10'd6 & drawY == 10'd6) | 
		(drawX > 10'd1 & drawY == 10'd7) | 
		(drawX < 10'd7 & drawY == 10'd8) | 
		(drawX < 10'd7 & drawY == 10'd9)) ? 1'b1 : 1'b0;
	end
	else if(direction == 4'd2) // left
	begin
		o = ((drawX > 10'd2 & drawX < 10'd10 & drawY == 10'd0) | 
		(drawX > 10'd2 & drawX < 10'd10 & drawY == 10'd1) | 
		(drawX > 10'd3 & drawX < 10'd8 & drawY == 10'd2) | 
		(drawX > 10'd3 & drawX < 10'd8 & drawY == 10'd3) | 
		(drawX < 10'd8 & drawY == 10'd4) | 
		(drawX > 10'd3 & drawX < 10'd8 & drawY == 10'd5) | 
		(drawX > 10'd3 & drawX < 10'd8 & drawY == 10'd6) | 
		(drawX > 10'd2 & drawX < 10'd10 & drawY == 10'd7) | 
		(drawX > 10'd2 & drawX < 10'd10 & drawY == 10'd8)) ? 1'b1 : 1'b0;
	end
	else if(direction == 4'd0) // down
	begin
		o = (((drawX < 10'd2 | (drawX > 10'd6 & drawX < 10'd9)) & drawY == 10'd0) | 
		((drawX < 10'd2 | (drawX > 10'd6 & drawX < 10'd9)) & drawY == 10'd1) | 
		(drawX < 10'd9 & drawY == 10'd2) | 
		(drawX < 10'd9 & drawY == 10'd3) | 
		(drawX < 10'd9 & drawY == 10'd4) | 
		(drawX < 10'd9 & drawY == 10'd5) | 
		((drawX < 10'd2 | drawX == 10'd4 | (drawX > 10'd6 & drawX < 10'd9)) & drawY == 10'd6) | 
		(drawX == 10'd4 & drawY == 10'd7) | 
		(drawX == 10'd4 & drawY == 10'd8) | 
		(drawX == 10'd4 & drawY == 10'd9)) ? 1'b1 : 1'b0;
	end
	else if(direction == 4'd1) //up
	begin
		o = ((drawX == 10'd4 & drawY == 10'd0) | 
		(drawX == 10'd4 & drawY == 10'd1) | 
		(drawX == 10'd4 & drawY == 10'd2) | 
		((drawX < 10'd2 | drawX == 10'd4 | (drawX > 10'd6 & drawX < 10'd9)) & drawY == 10'd3) | 
		(drawX < 10'd9 & drawY == 10'd4) | 
		(drawX < 10'd9 & drawY == 10'd5) | 
		(drawX < 10'd9 & drawY == 10'd6) | 
		(drawX < 10'd9 & drawY == 10'd7) | 
		((drawX < 10'd2 | (drawX > 10'd6 & drawX < 10'd9)) & drawY == 10'd8) | 
		((drawX < 10'd2 | (drawX > 10'd6 & drawX < 10'd9)) & drawY == 10'd9)) ? 1'b1 : 1'b0;
	end
	
	//11*11
	/*if(KEY[0] == 1'b0) //right
	begin
		o = ((drawX < 10'd9 & drawY == 10'd0) | 
		(drawX < 10'd9 & drawY == 10'd1) | 
		(drawX < 10'd9 & drawY == 10'd2) | 
		(drawX > 10'd1 & drawX < 10'd7 & drawY == 10'd3) | 
		(drawX > 10'd1 & drawX < 10'd7 & drawY == 10'd4) | 
		(drawX > 10'd1 & drawX < 10'd12 & drawY == 10'd5) | 
		(drawX > 10'd1 & drawX < 10'd7 & drawY == 10'd6) | 
		(drawX > 10'd1 & drawX < 10'd7 & drawY == 10'd7) |   
		(drawX < 10'd9 & drawY == 10'd8) | 
		(drawX < 10'd9 & drawY == 10'd9) | 
		(drawX < 10'd9 & drawY == 10'd10)) ? 1'b1 : 1'b0;
	end
	else if(KEY[3] == 1'b0) // left
	begin
		o = ((drawX > 10'd2 & drawX < 10'd11 & drawY == 10'd0) | 
		(drawX > 10'd2 & drawX < 10'd11 & drawY == 10'd1) | 
		(drawX > 10'd2 & drawX < 10'd11 & drawY == 10'd2) | 
		(drawX > 10'd4 & drawX < 10'd9 & drawY == 10'd3) | 
		(drawX > 10'd4 & drawX < 10'd9 & drawY == 10'd4) | 
		(drawX < 10'd9 & drawY == 10'd5) | 
		(drawX > 10'd4 & drawX < 10'd9 & drawY == 10'd6) | 
		(drawX > 10'd4 & drawX < 10'd9 & drawY == 10'd7) |   
		(drawX > 10'd2 & drawX < 10'd11 & drawY == 10'd8) | 
		(drawX > 10'd2 & drawX < 10'd11 & drawY == 10'd9) | 
		(drawX > 10'd2 & drawX < 10'd11 & drawY == 10'd10)) ? 1'b1 : 1'b0;
			
	end
	else if(KEY[1] == 1'b0) // down
	begin
		o = (((drawX < 10'd3 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd0) | 
		((drawX < 10'd3 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd1) | 
		(drawX < 10'd11 & drawY == 10'd2) | 
		(drawX < 10'd11 & drawY == 10'd3) | 
		(drawX < 10'd11 & drawY == 10'd4) | 
		(drawX < 10'd11 & drawY == 10'd5) | 
		((drawX < 10'd3 | drawX == 10'd5 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd6) | 
		((drawX < 10'd3 | drawX == 10'd5 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd7) |   
		(drawX == 10'd5 & drawY == 10'd8) | 
		(drawX == 10'd5 & drawY == 10'd9) | 
		(drawX == 10'd5 & drawY == 10'd10)) ? 1'b1 : 1'b0;
	end
	else if(KEY[2] == 1'b0) //up
	begin
		o = ((drawX == 10'd5 & drawY == 10'd0) | 
		(drawX == 10'd5 & drawY == 10'd1) | 
		(drawX == 10'd5 & drawY == 10'd2) | 
		((drawX < 10'd3 | drawX == 10'd5 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd3) | 
		((drawX < 10'd3 | drawX == 10'd5 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd4) | 
		(drawX < 10'd11 & drawY == 10'd5) | 
		(drawX < 10'd11 & drawY == 10'd6) | 
		(drawX < 10'd11 & drawY == 10'd7) |   
		(drawX < 10'd11 & drawY == 10'd8) | 
		((drawX < 10'd3 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd9) | 
		((drawX < 10'd3 | (drawX > 10'd7 & drawX < 10'd11)) & drawY == 10'd10)) ? 1'b1 : 1'b0;
	end*/
end
endmodule














/*reg [3:0] boxh;
reg [3:0] boxv;

[1:0] S;
[1:0] NS;

parameter
	START: 2'b00;
	READ: 2'01;
	DONE: 2'10;

always @ (posedge clk or negedge rst)
	if(rst == 1'b0)
		S <= START;
	else
		S <= NS;

always @ (*)
begin
	START: NS = READ;
	READ: NS = DONE;
	DONE: NS = DONE;
end

always @ (posedge clk or negedge rst)
	if(rst == 1'b0)
		//tilemap <= 8'd90;
		boxh <= 4'd10;
		boxv <= 4'd9;
		blueX <= 10'd5;
		blueY <= 10'd60;
		bdraw <= 1'd0;
	else
		case (S)
			START:
			READ:
			begin
	
			end
			DONE:	*/