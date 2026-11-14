Tested Oct 31st - by Peter

This is the framebuffer code implemented where the top level module implements pixels being drawn to the buffer.

To operate:
- turn on and reset - press KEY[0] - you should get rick rolled
- Set the SW[7:0] to 8'hFF (this will color the pixel white; 8'h00 is black) - note the byte is copied into R, G, B on line 206 of the top module
- press KEY[1] to write the pixel to location address 0
- press KEY[2] to increment the address location by 1.  The LEDR should show 8'b00000001
- you can change SW[7:0] for another color
- press KEY[1] to ...
and so on