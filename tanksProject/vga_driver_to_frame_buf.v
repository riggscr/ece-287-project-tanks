module vga_driver_to_frame_buf	(
    	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	//input 		          		AUD_ADCDAT,
	//inout 		          		AUD_ADCLRCK,
	//inout 		          		AUD_BCLK,
	//output		          		AUD_DACDAT,
	//inout 		          		AUD_DACLRCK,
	//output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	//output		          		FPGA_I2C_SCLK,
	//inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	//output		     [6:0]		HEX4,
	//output		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	output		          		VGA_BLANK_N,
	output		     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1

);

// Turn off all displays.
assign	HEX0		=	7'h00;
assign	HEX1		=	7'h00;
assign	HEX2		=	7'h00;
assign	HEX3		=	7'h00;

// DONE STANDARD PORT DECLARATION ABOVE
/* HANDLE SIGNALS FOR CIRCUIT */
wire clk;
wire rst;

assign clk = CLOCK_50;
assign rst = SW[0];

wire [9:0]SW_db;

debounce_switches db(
.clk(clk),
.rst(rst),
.SW(SW), 
.SW_db(SW_db)
);

// VGA DRIVER
wire active_pixels; // is on when we're in the active draw space
wire frame_done;
wire [9:0]x; // current x
wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

/* the 3 signals to set to write to the picture */
reg [14:0] the_vga_draw_frame_write_mem_address;
reg [23:0] the_vga_draw_frame_write_mem_data;
reg the_vga_draw_frame_write_a_pixel;

/* This is the frame driver point that you can write to the draw_frame */
vga_frame_driver my_frame_driver(
	.clk(clk),
	.rst(rst),

	.active_pixels(active_pixels),
	.frame_done(frame_done),

	.x(x),
	.y(y),

	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_CLK(VGA_CLK),
	.VGA_HS(VGA_HS),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_VS(VGA_VS),
	.VGA_B(VGA_B),
	.VGA_G(VGA_G),
	.VGA_R(VGA_R),

	/* writes to the frame buf - you need to figure out how x and y or other details provide a translation */
	.the_vga_draw_frame_write_mem_address(the_vga_draw_frame_write_mem_address),
	.the_vga_draw_frame_write_mem_data(the_vga_draw_frame_write_mem_data),
	.the_vga_draw_frame_write_a_pixel(the_vga_draw_frame_write_a_pixel)
);

/* idx_location stores all the locations in the */
reg [14:0] idx_location;
reg [4:0] direction;
reg [15:0] i;
reg [9:0] xcoor;
reg [9:0] ycoor;
reg [9:0] prev_BX;
reg [9:0] prev_BY;
reg makeBox;
reg stop;

//wire [3:0] blue_dir;

//subcount instantiation
//subcount blue_subcount(KEY[3:0], clk, rst, blue_dir);

//sprite instantiation
btankmap sprite(drawX, drawY, direction, bdraw);

reg [7:0]S;
reg [7:0]NS;

// Blue Box Personalities
reg [9:0] blueX;
reg [9:0] blueY;
reg [9:0] drawX;
reg [9:0] drawY;
reg [3:0] key;
wire bdraw;


// tank agnostic
reg [9:0] boxh;
reg [9:0] boxv;

parameter 
	START 			= 8'd0,
	// W2M is write to memory
	W2M_INIT 		= 8'd1,
	W2M_COND 		= 8'd2,
	W2M_INC 			= 8'd3,
	W2M_DONE 		= 8'd4,
	// The RFM = READ_FROM_MEMOERY reading cycles
	RFM_INIT_START = 8'd5,
	RFM_INIT_WAIT 	= 8'd6,
	RFM_DRAWING 	= 8'd7,
	ERROR 			= 8'hFF;

parameter MEMORY_SIZE = 16'd19200; // 160*120 // Number of memory spots ... highly reduced since memory is slow
parameter PIXEL_VIRTUAL_SIZE = 16'd4; // Pixels per spot - therefore 4x4 pixels are drawn per memory location
parameter BOXV	= 10'd10; // vertical max length of box
parameter BOXH = 10'd09; // horizontal max length of box
/* ACTUAL VGA RESOLUTION */
parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480;

/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide */
parameter VIRTUAL_PIXEL_WIDTH = VGA_WIDTH/PIXEL_VIRTUAL_SIZE; // 160
parameter VIRTUAL_PIXEL_HEIGHT = VGA_HEIGHT/PIXEL_VIRTUAL_SIZE; // 120

parameter
	INIT = 8'd8,
	RESET = 8'd17,
	KEY_SEL = 8'd9,
	MOVE = 8'd10,
	DRAW = 8'd11,
	WAITD = 8'd12,
	WAITU = 8'd13,
	WAITL = 8'd14,
	WAITR = 8'd15,
	CLEANUP = 8'd16;
	
wire [7:0] scan_code;
wire scan_ready;
reg [3:0] blue_dir_reg;
reg key_handled;
reg ignore_next;

wire [3:0] blue_dir_wire;

//assign blue_dir_wire = blue_dir_reg;

assign LEDR[7:0] = scan_code;
assign LEDR[8]   = ignore_next;
assign LEDR[9]   = scan_ready;

//ps2 instantiation                                                        rst: gemini assumed active-low for SW[0] - may need to change
ps2 my_keyboard(.clock_key(PS2_CLK), .data_key(PS2_DAT), .clock_fpga(clk), .reset(rst), .data_out(scan_code), .new_code(scan_ready));

//ps2 code
always @(posedge clk or negedge rst) begin
	if(rst == 1'b0) begin
		blue_dir_reg <= 4'd0;
		key_handled <= 1'b0;
		ignore_next <= 1'b0;
	end
	else begin
		if(scan_ready && (!key_handled)) begin
			key_handled <= 1'b1;
			
			if(scan_code == 8'hF0) begin
				// Key released: flag the next incoming code to be ingonred
				ignore_next <= 1'b1;
			end
			// Code following F0, clear the flag and do nothing
			else if(ignore_next == 1'b1) begin
				ignore_next <= 1'b0;
			end
			// Valid, fresh key press
			else begin
				case(scan_code)
					8'h1B : blue_dir_reg <= 4'b0001; // S -> down
					8'h1D : blue_dir_reg <= 4'b0010; // W -> up
					8'h1C : blue_dir_reg <= 4'b0100; // A -> left
					8'h23 : blue_dir_reg <= 4'b1000; // D -> right
					default : blue_dir_reg <= 4'b0000;
				endcase
			end
		end
		else if(!scan_ready) begin
			key_handled <= 1'b0;
		end
		
		if(S == MOVE  && blue_dir_reg != 4'b0000) begin
			blue_dir_reg <= 4'b0000;
		end
	end	
end	
	
//main fsm	
always @ (posedge clk or negedge rst)
	if(rst == 1'b0)
		S <= RESET;
	else
		S <= NS;

always @ (*)
begin
	case (S)
		INIT: NS = RESET;
		RESET:
		begin
			if(idx_location == MEMORY_SIZE)
				NS = DRAW;
			else
				NS = RESET;
		end
		KEY_SEL: 
		begin
			if(blue_dir_reg[0] == 1'b1)
				NS = MOVE;
			else if(blue_dir_reg[1] == 1'b1)
				NS = MOVE;
			else if(blue_dir_reg[2] == 1'b1)
				NS = MOVE;
			else if(blue_dir_reg[3] == 1'b1)
				NS = MOVE;
			else
				NS = KEY_SEL;
		end
		MOVE: NS = DRAW;
		DRAW: begin 
				if(makeBox == 1'b1)
					NS = CLEANUP;
				else
					NS = DRAW;
				end
		CLEANUP: begin 
					if(stop == 1'b1)
						NS = KEY_SEL;
					else
						NS = CLEANUP;
					end
		default: NS = INIT;
	endcase
end

always @ (posedge clk or negedge rst)
begin
	if(rst == 1'b0)
	begin
		idx_location <= 15'd0;
		xcoor <= 10'd0;
		ycoor <= 10'd0;
		prev_BX <= 10'd0;
		prev_BY <= 10'd0;
		blueX <= 10'd5;
		blueY <= 10'd60;
		drawX <= 10'd0;
		stop <= 1'b0;
		drawY <= 10'd0;
		makeBox <= 1'b0;
		boxv <= 10'd10;
		boxh <= 10'd9;
		direction <= 4'd0;
		the_vga_draw_frame_write_mem_address <= 15'd0;
		the_vga_draw_frame_write_mem_data <= 24'd0;
		the_vga_draw_frame_write_a_pixel <= 1'b0;
	end
	else
	begin
		case (S)
			INIT:
			begin			
				idx_location <= 15'd0;
				xcoor <= 10'd0;
				ycoor <= 10'd0;
				prev_BX <= 10'd0;
				prev_BY <= 10'd0;
				makeBox <= 1'b0;
				stop <= 1'b0;
				blueX <= 10'd5;
				blueY <= 10'd60;
				drawX <= 10'd0;
				drawY <= 10'd0;
				boxv <= 10'd10;
				boxh <= 10'd9;
				direction <= 4'd0;
				the_vga_draw_frame_write_mem_address <= 15'd0;
				the_vga_draw_frame_write_mem_data <= 24'd0;
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			RESET:
			begin
				the_vga_draw_frame_write_a_pixel <= 1'b1;
				idx_location <= ((15'd120 * xcoor) + ycoor);
				the_vga_draw_frame_write_mem_address <= ((15'd120 * xcoor) + ycoor);
				
				//orange border generation
				if((xcoor < VIRTUAL_PIXEL_WIDTH) & (ycoor < 10'd2 | ycoor > 10'd117))
					the_vga_draw_frame_write_mem_data <= 24'hFF781F;
				else if((xcoor < 10'd2 | xcoor > 10'd157) & (ycoor < VIRTUAL_PIXEL_HEIGHT))
					the_vga_draw_frame_write_mem_data <= 24'hFF781F;
				else
					the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
				
				//increment
				if(ycoor == 10'd119)
				begin
					xcoor <= xcoor + 1'b1;
					ycoor <= 10'd0;
				end
				else
					ycoor <= ycoor + 1'b1;
			end
			KEY_SEL: 
			begin
				stop <= 1'b0;
				the_vga_draw_frame_write_a_pixel <= 1'b0;
				if(blue_dir_reg[0] == 1'b1)
					direction <= 4'd0; // down
				else if(blue_dir_reg[1] == 1'd1)
					direction <= 4'd1; // up
				else if(blue_dir_reg[2] == 1'd1)
					direction <= 4'd2; // left
				else if(blue_dir_reg[3] == 1'd1)
					direction <= 4'd3; // right
			end
			MOVE: 
			begin
					prev_BX <= blueX;
					prev_BY <= blueY;
					the_vga_draw_frame_write_a_pixel <= 1'b0;
					case (direction)
						4'd0: //down
						begin
							//prev_BX <= blueX;
							//prev_BY <= blueY;
							boxv <= 10'd9;
							boxh <= 10'd10;
							blueY <= (blueY < 10'd119) ? blueY + 1'b1 : blueY;
							//the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
						4'd1: //up
						begin
							//prev_BX <= blueX;
							//prev_BY <= blueY;
							boxv <= 10'd9;
							boxh <= 10'd10;
							blueY <= (blueY > 10'd0) ? blueY - 1'b1 : blueY;
							//the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
						4'd2: //left
						begin
							//prev_BX <= blueX;
							//prev_BY <= blueY;
							boxv <= 10'd10;
							boxh <= 10'd9;
							blueX <= (blueX > 10'd0) ? blueX - 1'b1 : blueX;
							//the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
						4'd3: //right
						begin
							//prev_BX <= blueX;
							//prev_BY <= blueY;
							boxv <= 10'd10;
							boxh <= 10'd9;
							blueX <= (blueX < 10'd159) ? blueX + 1'b1 : blueX;
							//the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
					endcase
			end
			DRAW:
				begin
					the_vga_draw_frame_write_a_pixel <= 1'b1;
					if(makeBox == 1'b0) begin
						the_vga_draw_frame_write_mem_address <= (15'd120 * (blueX + drawX)) + (blueY + drawY);
						if(bdraw == 1'b1)
							the_vga_draw_frame_write_mem_data <= 24'h4A4AF7;
						else
							the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
						if(drawX < (boxh - 1'b1))
							drawX <= drawX + 1'b1;
						else begin
							drawX <= 10'd0;
							if(drawY < (boxv - 1'b1))
								drawY <= drawY + 1'b1;
							else begin
								makeBox <= 1'b1;
								drawX <= 10'b0;
								drawY <= 10'b0;
							end
						end
					end
					
				end
			CLEANUP:
				begin
					if(stop == 1'b0) begin
						makeBox <= 1'b0;
						the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
						case (direction)
							4'd0: //down
							begin
								
								the_vga_draw_frame_write_mem_address <= (15'd120 * (prev_BX + drawX)) + prev_BY;
								the_vga_draw_frame_write_a_pixel <= 1'b1;
								if(drawX < (boxh - 1'b1))
									drawX <= drawX + 1'b1;
								else begin
									stop <= 1'b1;
									drawX <= 10'b0;
									drawY <= 10'b0;
								end
							end
							4'd1: //up
							begin
								the_vga_draw_frame_write_mem_address <= (15'd120 * (prev_BX + drawX)) + (prev_BY + boxv - 1'b1);
								the_vga_draw_frame_write_a_pixel <= 1'b1;
								if(drawX < (boxh - 1'b1))
									drawX <= drawX + 1'b1;
								else begin
									stop <= 1'b1;
									drawX <= 10'b0;
									drawY <= 10'b0;
								end
							end
							4'd2: //left
							begin
								the_vga_draw_frame_write_mem_address <= (15'd120 * (prev_BX + boxh - 1'b1)) + (prev_BY + drawY);
								the_vga_draw_frame_write_a_pixel <= 1'b1;
								if(drawY < (boxv - 1'b1))
									drawY <= drawY + 1'b1;
								else begin
									stop <= 1'b1;
									drawX <= 10'b0;
									drawY <= 10'b0;
								end
							end
							4'd3: //right
							begin
								the_vga_draw_frame_write_mem_address <= (15'd120 * prev_BX) + (prev_BY + drawY);
								the_vga_draw_frame_write_a_pixel <= 1'b1;
								if(drawY < (boxv - 1'b1))
									drawY <= drawY + 1'b1;
								else begin
									stop <= 1'b1;
									drawX <= 10'b0;
									drawY <= 10'b0;
								end
							end
						endcase
					end
				end
		endcase
	end
end
endmodule