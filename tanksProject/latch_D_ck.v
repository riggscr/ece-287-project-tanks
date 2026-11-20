module latch_D_ck (input D, 
						input ck, 
						output reg Q);

///assign Q = (ck==1) ? D : Q;

always @ (posedge ck) begin
	Q <= D;
end
	
endmodule