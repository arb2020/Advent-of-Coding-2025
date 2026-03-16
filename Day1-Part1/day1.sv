// day1.sv
module day1 #(parameter int WIDTH = 10) (
    input  logic [WIDTH-1:0] num,
    input  logic              direction,   // 0=LEFT, 1=RIGHT
    input  logic              valid,       // producer asserts when num/direction are valid
    output logic              ready,       // DUT asserts when it can accept a command

    input  logic              reset,       // active-low
    input  logic              clk,

    output logic [11:0]        count
);

  // -------------------------
  // State enum (self-contained)
  // -------------------------
  typedef enum logic [1:0] { RESET_S, IDLE_S, EXEC_S, COUNT_S } state_t;
  state_t current_state, next_state;

  // -------------------------
  // Registers
  // -------------------------
  logic [6:0] dial_num, dial_next;
  logic [11:0] count_next;

  // Latched instruction (captured on valid&&ready)
  logic [WIDTH-1:0] num_q;
  logic             dir_q;

  // -------------------------
  // Sequential: state + regs
  // -------------------------
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      current_state <= RESET_S;
      dial_num      <= 7'd50;
      count         <= 12'd0;
      num_q         <= '0;
      dir_q         <= 1'b0;
    end else begin
      current_state <= next_state;
      dial_num      <= dial_next;
      count         <= count_next;

      // Accept new command only on handshake
      if (valid && ready) begin
        num_q <= num;
        dir_q <= direction;
      end
    end
  end

  // -------------------------
  // Combinational: next logic
  // -------------------------
  always_comb begin
    // defaults (prevents latches)
    next_state = current_state;
    dial_next  = dial_num;
    count_next = count;
    ready      = 1'b0;

    unique case (current_state)

      RESET_S: begin
        next_state = IDLE_S;
      end

      IDLE_S: begin
        ready = 1'b1;               // we can accept a command now
        if (valid) begin
          next_state = EXEC_S;      // once accepted, go execute next cycle
        end
      end

      EXEC_S: begin
        // Apply the captured instruction (num_q/dir_q)
        logic [6:0] step;
        step = num_q % 100;

        if (dir_q == 1'b0) begin
          // LEFT: subtract modulo 100
          dial_next = (dial_num + 7'd100 - step) % 100;
        end else begin
          // RIGHT: add modulo 100
          dial_next = (dial_num + step) % 100;
        end

        next_state = COUNT_S;
      end

      COUNT_S: begin
        // Count after the move
        if (dial_num == 7'd0)
          count_next = count + 12'd1;

        next_state = IDLE_S;
      end

      default: begin
        next_state = RESET_S;
      end

    endcase
  end

endmodule
