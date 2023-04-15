`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2023 01:08:28
// Design Name: 
// Module Name: spi_sys
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Serial Peripheral Interface Circuit 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


/* ---- Construction;

Background:
1. this module is created based on the following HW signals;
2. other SPI signals such as chip select, Data-or-command are emulated on the software end;

Necessary HW Signals:
1. SCL; clock to drive both master and slave;
2. MOSI: master out slave in
3. MISO: master in slave out;

SPI other Control: 
1. CPOL; clock polarity
2. CPHA: clock phase;

Important Idea (FSDM main states):
1. Sampling (reading slave) and Shifting (writing to slave) are always
conducted in the same clock period BUT on the different edge of the clock;
depending on CPOL and CPHA;
(Reference: https://onlinedocs.microchip.com/pr/GUID-835917AF-E521-4046-AD59-DCB458EB8466-en-US-1/index.html?GUID-E4682943-46B9-4A20-A62C-33E8FD3343A3)

2. By above, the FSMD has two main States:
    State A: is where the sampling occurs (happening on the first half of the SPI clock period);
    State B: is where the shifting occurs (happening on the second half of the SPI clock period);
3. Other states are there depending on the combination of {CPHA, CPOL};
    
SPI Clock Construction:
1. The clock, although is derived by the system clock; is implicitly
    based on the state of the FSDM, as discussed above;
2. By the Idea above, we spend the first half of the clock period in System A;
    and the second half in State B;
3. So, the change in the clock is driven by the current states as above;

*/

module spi_sys(

    );
endmodule
