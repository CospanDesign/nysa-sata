module test_in (
  input               clk,
  input               rst,

  input               enable,

  input       [1:0]   ready,
  input       [23:0]  size,
  output  reg [1:0]   activate,
  output  reg [31:0]  data,
  output  reg         strobe
);


//Parameters
//Registers/Wires
reg           [23:0]  count;
//Sub modules
//Asynchronous Logic
//Synchronous Logic

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    activate          <=  0;
    data              <=  0;
    strobe            <=  0;
    count             <=  0;
  end
  else begin
    strobe            <=  0;
    if ((ready > 0) && (activate == 0) && enable) begin
      //A FIFO is available
      count           <=  0;
      if (ready[0]) begin
        activate[0]   <=  1;
      end
      else begin
        activate[1]   <=  1;
      end
    end
    else if (activate > 0) begin
      if (count < size) begin
        data          <=  count;
        count         <=  count + 1;
        strobe        <=  1;
      end
      else begin
        activate      <=  0;
      end
    end

  end
end

endmodule
