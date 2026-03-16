// day1_tb.sv
module day1_tb;
  localparam int WIDTH = 10;

  logic [WIDTH-1:0] num;
  logic             direction;
  logic             valid;
  logic             ready;
  logic             reset, clk;
  logic [19:0]       count;

  int fd;
  string line;
  string dir_str;
  bit dir_send;
  int unsigned k;
  // DUT
  day1 #(.WIDTH(WIDTH)) dut (
    .num(num),
    .direction(direction),
    .valid(valid),
    .ready(ready),
    .reset(reset),
    .clk(clk),
    .count(count)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Pretty state name (matches DUT enum ordering)
  function automatic string st_name(input logic [1:0] s);
    case (s)
      2'd0: st_name = "RESET";
      2'd1: st_name = "IDLE";
      2'd2: st_name = "EXEC";
      2'd3: st_name = "COUNT";
      default: st_name = "UNK";
    endcase
  endfunction

  // Monitor (dial_num is internal, so peek hierarchically)
  always @(posedge clk) begin
    $display("t=%0t st=%s ready=%0b valid=%0b dir=%0b num=%0d dial=%0d count=%0d modcount=%0d",
             $time, st_name(dut.current_state), ready, valid, direction, num, 
             dut.dial_num, count, dut.modulo_count);
  end

  // Apply one step using valid/ready handshake
  task automatic send_step(input logic dir, input int unsigned k);
  // Wait for a clock edge where ready is high
  @(posedge clk);
  while (!ready) @(posedge clk);

  // Drive command *immediately after* that posedge so it is stable
  // for the *next* posedge where the DUT samples it.
  direction <= dir;
  num       <= k[WIDTH-1:0];
  valid     <= 1'b1;

  // Hold valid high for one full cycle (so sampling can't be missed)
  @(posedge clk);
  valid <= 1'b0;

  // Optional: wait one more cycle before allowing next command,
  // keeps waveforms easy to read
  @(posedge clk);
endtask

  initial begin
    // init
    num = '0;
    direction = 1'b0;
    valid = 1'b0;
    reset = 1'b0;

    // reset for a couple cycles
    repeat (2) @(posedge clk);
    reset = 1'b1;

   
    fd = $fopen("input.txt", "r");
    if (fd == 0) begin
      $fatal("Failed to open input.txt");
    end   
    // read each line, send command
    while (!$feof(fd)) begin
      line = "";
      if($fgets(line, fd)) begin
        // parse line
        if ($sscanf(line, "%1s%0d", dir_str, k) != 2) begin
          $fatal("Failed to parse line: %s", line);
        end
        else begin
          dir_send = (dir_str == "R") ? 1'b1 : 1'b0;
          send_step(dir_send, k);
        end
      end 
    end
    $fclose(fd);

    // wait for pipeline to finish
    repeat (6) @(posedge clk);

    $display("FINAL COUNT (password for this sequence) = %0d", count);
    $finish;
  end

endmodule
