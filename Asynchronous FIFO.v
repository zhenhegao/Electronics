module Asynchronous FIFO
   parameter DATA_WIDTH = 8;
   parameter DATA_DEPTH = 8;
   parameter ADDRESS_WIDTH = 3;

 
//**********************Port definition***********************//
 
           input Write_Enable;
           input Read_Enable;
           input [DATA_WIDTH-1:0] Data_In;
 
           input Write_Clock;
           input Write_Reset_Enable;
 
           input Read_Clock;
           input Read_Reset_Enable;
 
           output Full;
           output Empty;
    output reg [DATA_WIDTH-1:0] Data_Out;
 
//******************write address generation******************//
 
    reg [ADDRESS_WIDTH:0] Write_Address_Pointer; 
    always@(posedge Write_Clock or negedge Write_Reset_Enable)
        if(!Write_Reset_Enable)
               Write_Address_Pointer <= 'd0; 
    else if((Full == 'd0) && (Write_Enable))begin
        if(Write_Address_Pointer >= 'd7)
                  Write_Address_Pointer <= 'd0;
               else
                  Write_Address_Pointer <= Write_Address_Pointer + 1'd1;
            end
            else 
               Write_Address_Pointer <= Write_Address_Pointer;
    wire [ADDR_WIDTH-1:0] Write_Address;
     assign Write_Address= Write_Address_Pointer[ADDR_WIDTH-1:0];
//******************read address generation*******************//
    reg [ADDR_WIDTH:0] Read_Address_Pointer;
    always@(posedge Read_Clock or negedge Read_Reset_Enable)
        if(!Read_Reset_Enable)
               Read_Address_Pointer <= 'd0; 
    else if((Empty == 'd0) && (Read_Enable))begin
        if(Read_Address_Pointer >= 'd7)
                  Read_Address_Pointer <= 'd0;
               else
                  Read_Address_Pointer <= Read_Address_Pointer + 1'd1;
            end
            else 
               Read_Address_Pointer <= Read_Address_Pointer;
 
    wire [ADDR_WIDTH-1:0] Read_Address;
    assign Read_Address = Read_Address_Pointer[ADDRESS_WIDTH-1:0];
 
//****************Binary conversion Gray code*****************//
 
    wire [ADDRESS_WIDTH:0] Write_Address_Gray;
    assign Write_Address_Gray = (Write_Address_Pointer >> 1) ^ Write_Address_Pointer;
    wire [ADDRESS_WIDTH:0] Read_Address_Gray;
    assign Read_Address_Gray = (Read_Address_Pointer >> 1) ^ Read_Address_Pointer;
//************Cross-clock domain processing(CDC)**************//
 
    reg [ADDRESS_WIDTH:0] Write_Address_Gray_1;
    reg [ADDRESS_WIDTH:0] Write_Address_Gray_2;
    always@(posedge Reset_Clock or negedge Read_Reset_Enable)
        if(!Read_Reset_Enable)
        {Write_Address_Gray_2,Write_Address_Gray_1} <= 'd0;
            else
            {Write_Address_Gray_2,Write_Address_Gray_1} <= {Write_Address_Gray_1,WriteAddress_Gray};
    reg [ADDR_WIDTH:0] Read_Address_Gray_1;
    reg [ADDR_WIDTH:0] Read_Address_Gray_2;
    always@(posedge Write_Clock or negedge Write_Reset_Enable)
        if(!Write_Reset_Enable)
        {Read_Address_Gray_2,Read_Address_Gray_1} <= 'd0;
            else
            {Read_Address_Gray_2,Read_Address_Gray_1} <= {Read-Address_Gray_1,ReadAddress_Gray};
              
//****************empty full signal generation****************//
    
    assign Full  = ((Write_Address_Gray[ADDRESS_WIDTH:ADDRESS_WIDTH-1] !== Read_Address_Gray_2[ADDRESS_WIDTH:ADDRESS_WIDTH-1]) &&
                    (Write_Address_Gray[ADDRESS_WIDTH-2:0] == Read_Address_Gray_2[ADDRESS_WIDTH-2:0]) && (Write_Reset_Enable))? 'd1:'d0;
    assign Empty = ((Read_Address_Gray == Write_Address_Gray_2) && (Read_Reset_Enable))? 'd1:'d0;   
 
//***********************write to fifo************************//
 
            integer i;
    reg [ADDRESS_WIDTH-1:0] sram [0:DATA_DEPTH-1];
    always@(posedge Write_Clock or negedge Write_Reset_Enable)
          if(!Write_Reset_Enable)            
              for(i = 0; i < DATA_DEPTH;i = i + 1) begin
               sram[i] <= 'd0;
              end
    else if(Write_Enable && (!Full))
                sram[Write_Address] <= Data_In;
//******************read out to the fifo**********************//
    always@(posedge Read_Clock or negedge Read_Reset_Enable)
          if(!Read_Reset_Enable)            
               Data_Out <= 'd0; 
    else if(Read_Enable && (!Empty))
                Data_Out <= sram[Read_Address];
            else 
               Data_Out <= Data_Out;
                  
endmodule
