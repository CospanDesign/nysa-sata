module test_out (
  input               clk,
  input               rst,

  input               enable,

  input               ready,
  output  reg         activate,
  input       [23:0]  size,
  output  reg         strobe

);

reg           [23:0]  count;


always @ (posedge clk) begin
  if (rst) begin
    activate      <= 0;
    count         <=  0;
  end
  else begin
    strobe        <=  0;
    if (ready && !activate && enable) begin
      count       <=  0;
      activate    <=  1;
    end
    else if (activate) begin
      if (count < size) begin
        strobe    <=  1;
        count     <=  count + 1;
      end
      else begin
        activate  <=  0;
      end
    end
  end
end

endmodule
