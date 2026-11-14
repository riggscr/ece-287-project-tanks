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
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
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
reg [9:0] prev_xcoor;
reg [9:0] prev_ycoor;
reg [7:0]S;
reg [7:0]NS;
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

/* ACTUAL VGA RESOLUTION */
parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480;

/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide */
parameter VIRTUAL_PIXEL_WIDTH = VGA_WIDTH/PIXEL_VIRTUAL_SIZE; // 160
parameter VIRTUAL_PIXEL_HEIGHT = VGA_HEIGHT/PIXEL_VIRTUAL_SIZE; // 120

parameter
	INIT = 8'd8,
	KEY_SEL = 8'd9,
	MOVE = 8'd10,
	DRAW = 8'd11,
	WAITD = 8'd12,
	WAITU = 8'd13,
	WAITL = 8'd14,
	WAITR = 8'd15,
	CLEANUP = 8'd16;

always @ (posedge clk or negedge rst)
	if(rst == 1'b0)
		S <= INIT;
	else
		S <= NS;

always @ (*)
begin
	case (S)
		INIT: NS = KEY_SEL;
		KEY_SEL: 
		begin
			if(KEY[1] == 1'b0)
				NS = WAITD;
			else if(KEY[2] == 1'b0)
				NS = WAITU;
			else if(KEY[3] == 1'b0)
				NS = WAITL;
			else if(KEY[0] == 1'b0)
				NS = WAITR;
			else
				NS = KEY_SEL;
		end
		MOVE: NS = DRAW;
		DRAW: NS = CLEANUP;
		WAITD:
		begin
			if(KEY[1] == 1'b1)
				NS = MOVE;
			else 
				NS = WAITD;
		end
		WAITU:
		begin
			if(KEY[2] == 1'b1)
				NS = MOVE;
			else
				NS = WAITU;
		end
		WAITL:
		begin
			if(KEY[3] == 1'b1)
				NS = MOVE;
			else
				NS = WAITL;
		end
		WAITR:
		begin
			if(KEY[0] == 1'b1)
				NS = MOVE;
			else
				NS = WAITR;
		end
		CLEANUP: NS = KEY_SEL;
		default: NS = INIT;
	endcase
end

always @ (posedge clk or negedge rst)
begin
	if(rst == 1'b0)
	begin
		xcoor <= 10'd0;
		ycoor <= 10'd0;
		prev_xcoor <= 10'd0;
		prev_ycoor <= 10'd0;		
		the_vga_draw_frame_write_mem_address <= 15'd0;
		the_vga_draw_frame_write_mem_data <= 24'd0;
		the_vga_draw_frame_write_a_pixel <= 1'b0;
	end
	else
	begin
		case (S)
			INIT:
			begin
				idx_location <= 15'd120 * xcoor + ycoor;
				xcoor <= 10'd0;
				ycoor <= 10'd0;
				prev_xcoor <= 10'd0;
				prev_ycoor <= 10'd0;
				the_vga_draw_frame_write_mem_address <= 15'd0;
				the_vga_draw_frame_write_mem_data <= 24'd0;
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			KEY_SEL: 
			begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
				if(KEY[1] == 1'b0)
					direction <= 4'd0;
				else if(KEY[2] == 1'd0)
					direction <= 4'd1;
				else if(KEY[3] == 1'd0)
					direction <= 4'd2;
				else if(KEY[0] == 1'd0)
					direction <= 4'd3;
			end
			WAITU: the_vga_draw_frame_write_a_pixel <= 1'b0;
			WAITD: the_vga_draw_frame_write_a_pixel <= 1'b0;
			WAITL: the_vga_draw_frame_write_a_pixel <= 1'b0;
			WAITR: the_vga_draw_frame_write_a_pixel <= 1'b0;
			MOVE: 
			begin
					case (direction)
						4'd0: //down
						begin
							//idx_location <= idx_location + 1'b1;
							prev_xcoor <= xcoor;
							prev_ycoor <= ycoor;							
							ycoor <= (ycoor < 10'd119) ? ycoor + 1'b1 : ycoor;
							the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
						4'd1: //up
						begin
							//idx_location <= idx_location - 1'b1;
							prev_xcoor <= xcoor;
							prev_ycoor <= ycoor;
							ycoor <= (ycoor > 10'd0) ? ycoor - 1'b1 : ycoor;
							the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
						4'd2: //left
						begin
							//idx_location <= idx_location - 15'd120;
							prev_xcoor <= xcoor;
							prev_ycoor <= ycoor;
							xcoor <= (xcoor > 10'd0) ? xcoor - 1'b1 : xcoor;
							the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
						4'd3: //right
						begin
							//idx_location <= idx_location + 15'd120;
							prev_xcoor <= xcoor;
							prev_ycoor <= ycoor;
							xcoor <= (xcoor < 10'd159) ? xcoor + 1'b1 : xcoor;
							the_vga_draw_frame_write_a_pixel <= 1'b0;
						end
					endcase
			end
			DRAW:
				begin
					the_vga_draw_frame_write_mem_address <= 15'd120 * xcoor + ycoor;
					the_vga_draw_frame_write_mem_data <= 24'h4A4AF7;
					the_vga_draw_frame_write_a_pixel <= 1'b1;
				end
			CLEANUP:
				begin
					case (direction)
						4'd0: //down
						begin
							the_vga_draw_frame_write_mem_address <= 15'd120 * prev_xcoor + prev_ycoor;
							the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
							the_vga_draw_frame_write_a_pixel <= 1'b1;
						end
						4'd1: //up
						begin
							the_vga_draw_frame_write_mem_address <= 15'd120 * prev_xcoor + prev_ycoor;
							the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
							the_vga_draw_frame_write_a_pixel <= 1'b1;
						end
						4'd2: //left
						begin
							the_vga_draw_frame_write_mem_address <= 15'd120 * prev_xcoor + prev_ycoor;
							the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
							the_vga_draw_frame_write_a_pixel <= 1'b1;
						end
						4'd3: //right
						begin
							the_vga_draw_frame_write_mem_address <= 15'd120 * prev_xcoor + prev_ycoor;
							the_vga_draw_frame_write_mem_data <= 24'hF7D88F;
							the_vga_draw_frame_write_a_pixel <= 1'b1;
						end
					endcase
				end
		endcase
	end
end
endmodule