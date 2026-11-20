module verificare(input clock_fpga, 						//fpga clock signal
						input [10:0] data_in_parallel, 		//parallel data from SIPO register
						output reg ok, 							//indicates that the data received is correct, active on 1
						input [3:0] count							//counter from SIPO register
						);

////////internal registers///////
//reg sum;
//wire par_check;	//parity check

wire odd_parity_ok = ^data_in_parallel[9:1];

always @ (posedge clock_fpga) begin
	/*if (count < 11) begin
		sum <= sum + data_in_parallel[count-1]; 	//calculus of parity
	end
	else*/ 
	if (count == 11) begin
		if (data_in_parallel[0] == 1'b0 && data_in_parallel[10] == 1'b1 && odd_parity_ok) begin
			ok <= 1'b1; //active if the start, stop and parity bits are correct
		end
		else begin
			ok <= 1'b0;	
		end
	end
	else begin
		ok <= 1'b0;
	end
end
		
//assign par_check = ~sum;


endmodule 
