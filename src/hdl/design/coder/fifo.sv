module ShiftFIFO #(
  parameter WIDTH = 10,
  parameter DEPTH = 3
) (
    input logic clk, rst_n, rst, 
    fifoWr_if.syncRx wr,
    fifoRd_if.syncTx rd
);
  logic [$clog2(DEPTH)-1:0] ptr;
  logic [WIDTH-1:0] shiftReg [DEPTH];
  assign wr.full = ptr == DEPTH-1;
  assign rd.empty = ~|ptr;
  always_ff @(posedge clk) begin
    for(int i=0; i<DEPTH; i++)
      if(!wr.full & wr.en)
        shiftReg[i] <= i == 0 ? wr.data : shiftReg[i-1];
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      ptr <= '0;
    end else if(rst) begin
      ptr <= '0;
    end else begin 
      case ({wr.en, rd.en})
        2'b01: begin
          if(!rd.empty)
            ptr <= ptr - 1;
        end
        2'b10: begin
          if(!wr.full)
            ptr <= ptr + 1;
        end
      endcase
    end
  end
  assign rd.data = shiftReg[ptr-1];
endmodule

module asyncFIFO #(
  parameter WIDTH = 10,
  parameter DEPTH = 64,
  parameter FWFT = 1
) (
  input logic rst_n,
  fifoWr_if.asyncRx wr,
  fifoRd_if.asyncTx rd
);

  fifoRd_if #(WIDTH) stdRd (rd.clk);
  asyncStdFIFO #(WIDTH, DEPTH) stdFIFO (rst_n, wr, stdRd);

  generate
    if(FWFT) begin

      struct {logic [WIDTH-1:0] current, next;} firstWord; 
      struct {
        enum logic [1:0]{EMPTY, FIRST, SECOND, NORMAL} current, next;
      } state;
      struct {logic current, next;} empty;

      always_ff @(posedge rd.clk or negedge rst_n) begin
        if(!rst_n)begin
          firstWord.current <= '0;
          empty.current <= 1;
          state.current <= EMPTY;
        end else begin
          firstWord.current <= firstWord.next;
          empty.current <= empty.next;
          state.current <= state.next;
        end
      end
      assign rd.empty = empty.current;

      always_comb begin
        firstWord.next = firstWord.current;
        empty.next = empty.current;
        stdRd.en = 0; 
        state.next = state.current;
        case(state.current)
          EMPTY: begin
            if(!stdRd.empty) begin
              stdRd.en = 1;
              state.next = FIRST;
            end
          end
          FIRST: begin
            firstWord.next = stdRd.data;
            if(!stdRd.empty) begin
              stdRd.en = 1;
              state.next = NORMAL;
            end else begin
              state.next = SECOND;
            end
            empty.next = 0;
          end
          SECOND: begin
            if(rd.en)
              firstWord.next = stdRd.data;
            if(stdRd.empty & rd.en) begin
              state.next = EMPTY;
              empty.next = 1;
            end else if(!stdRd.empty) begin
              stdRd.en = 1;
              state.next = NORMAL;
            end
          end
          NORMAL: begin
            if(rd.en)
              firstWord.next = stdRd.data;
            stdRd.en = rd.en;
            if(stdRd.empty & rd.en) begin
              state.next = SECOND;
            end
          end
        endcase
      end

      assign rd.data = firstWord.current;

    end else begin
      assign rd.data = stdRd.data;
      assign rd.empty = stdRd.empty;
      assign stdRd.en = rd.en;
    end
  endgenerate

endmodule

module syncFIFO #(
  parameter WIDTH = 10,
  parameter DEPTH = 3,
  parameter FWFT = 1
) (
  input logic clk, rst_n,
  fifoWr_if.syncRx wr,
  fifoRd_if.syncTx rd
);

  fifoRd_if #(WIDTH) stdRd (clk);
  syncStdFIFO #(WIDTH, DEPTH) stdFIFO (clk, rst_n, wr, stdRd);

  generate
    if(FWFT) begin

      struct {logic [WIDTH-1:0] current, next;} firstWord; 
      struct {
        enum logic [1:0]{EMPTY, FIRST, SECOND, NORMAL} current, next;
      } state;
      struct {logic current, next;} empty;

      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
          firstWord.current <= '0;
          empty.current <= 1;
          state.current <= EMPTY;
        end else begin
          firstWord.current <= firstWord.next;
          empty.current <= empty.next;
          state.current <= state.next;
        end
      end
      assign rd.empty = empty.current;

      always_comb begin
        firstWord.next = firstWord.current;
        empty.next = empty.current;
        stdRd.en = 0; 
        state.next = state.current;
        case(state.current)
          EMPTY: begin
            if(!stdRd.empty) begin
              stdRd.en = 1;
              state.next = FIRST;
            end
          end
          FIRST: begin
            firstWord.next = stdRd.data;
            if(!stdRd.empty) begin
              stdRd.en = 1;
              state.next = NORMAL;
            end else begin
              state.next = SECOND;
            end
            empty.next = 0;
          end
          SECOND: begin
            if(rd.en)
              firstWord.next = stdRd.data;
            if(stdRd.empty & rd.en) begin
              state.next = EMPTY;
              empty.next = 1;
            end else if(!stdRd.empty) begin
              stdRd.en = 1;
              state.next = NORMAL;
            end
          end
          NORMAL: begin
            if(rd.en)
              firstWord.next = stdRd.data;
            stdRd.en = rd.en;
            if(stdRd.empty & rd.en) begin
              state.next = SECOND;
            end
          end
        endcase
      end

      assign rd.data = firstWord.current;

    end else begin
      assign rd.data = stdRd.data;
      assign rd.empty = stdRd.empty;
      assign stdRd.en = rd.en;
    end
  endgenerate

endmodule

module syncStdFIFO #(
  parameter WIDTH = 10,
  parameter DEPTH = 3
) (
  input logic clk, rst_n,
  fifoWr_if.syncRx wr,
  fifoRd_if.syncTx rd
);

  ramWr_if #(WIDTH, DEPTH) ramWr(clk);
  ramRd_if #(WIDTH, DEPTH) ramRd(clk);
  Ram #(WIDTH, DEPTH) ram (ramWr, ramRd);

  struct {logic [$bits(ramWr.addr)-1:0] current, next;} wrPtr;
  struct {logic [$bits(ramRd.addr)-1:0] current, next;} rdPtr;
  struct {logic current, next;} full, empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wrPtr.current <= 0;
      rdPtr.current <= 0;
      full.current <= 0;
      empty.current <= 1;
    end else begin
      wrPtr.current <= wrPtr.next;
      rdPtr.current <= rdPtr.next;
      full.current <= full.next;
      empty.current <= empty.next;
    end
  end

  assign ramWr.addr = wrPtr.current;
  assign ramWr.data = wr.data;
  assign wr.full = full.current;

  assign ramRd.addr = rdPtr.current;
  assign rd.data = ramRd.data;
  assign rd.empty = empty.current;

  always_comb begin
    wrPtr.next = wrPtr.current;
    rdPtr.next = rdPtr.current;
    full.next = full.current;
    empty.next = empty.current;
    ramRd.en = 0;
    ramWr.en = 0;

    case({wr.en & !wr.full, rd.en & !rd.empty})
      2'b01: begin
        if(++rdPtr.next == wrPtr.current)
          empty.next = 1;
        ramRd.en = 1;
        if(wr.full)
          full.next = 0;
      end
      2'b10: begin
        if(++wrPtr.next == rdPtr.current)
          full.next = 1;
        ramWr.en = 1;
        if(rd.empty)
          empty.next = 0;
      end
      2'b11: begin
        wrPtr.next ++;
        rdPtr.next ++;
        ramRd.en = 1;
        ramWr.en = 1;
      end
    endcase
  end

endmodule

module asyncStdFIFO #(
  parameter WIDTH = 10,
  parameter DEPTH = 3
) (
  input logic rst_n,
  fifoWr_if.asyncRx wr,
  fifoRd_if.asyncTx rd
);
  localparam PTR_W = $clog2(DEPTH) + 1;

  ramWr_if #(WIDTH, DEPTH) ramWr(wr.clk);
  ramRd_if #(WIDTH, DEPTH) ramRd(rd.clk);
  Ram #(WIDTH, DEPTH) ram (ramWr, ramRd);
  assign ramWr.data = wr.data;
  assign rd.data = ramRd.data;

  struct {
    logic clk;
    struct {
      logic [PTR_W-1:0] current, next;
    } wrPtr, rdPtr;
    logic [PTR_W-1:0] gray[2];
    struct {logic current, next;} full;
  } wrDomain;

  struct {
    logic clk;
    struct {
      logic [PTR_W-1:0] current, next;
    } wrPtr, rdPtr;
    logic [PTR_W-1:0] gray[2];
    struct {logic current, next;} empty;
  } rdDomain;

  assign wrDomain.clk = wr.clk;
  always_ff @(posedge wr.clk or negedge rst_n) begin
    if(!rst_n) begin
      wrDomain.wrPtr.current <= 0;
      wrDomain.rdPtr.current <= 0;
      wrDomain.full.current <= 0;
      wrDomain.gray <= {'0, '0};
    end else begin
      wrDomain.wrPtr.current <= wrDomain.wrPtr.next;
      wrDomain.rdPtr.current <= wrDomain.rdPtr.next;
      wrDomain.full.current <= wrDomain.full.next;
      wrDomain.gray[0] <= rdDomain.rdPtr.current ^ (rdDomain.rdPtr.current >> 1);
      wrDomain.gray[1] <= wrDomain.gray[0];
    end
  end
  always_comb begin
    for(int i=PTR_W-1; i>=0; i--) begin
      if(i == PTR_W-1)
        wrDomain.rdPtr.next[i] = wrDomain.gray[1][i];
      else
        wrDomain.rdPtr.next[i] = wrDomain.rdPtr.next[i+1] ^ wrDomain.gray[1][i];
    end
    wrDomain.wrPtr.next = wrDomain.wrPtr.current;
    ramWr.en = 0;

    if(wr.en & !wr.full) begin
      wrDomain.wrPtr.next ++;
      ramWr.en = 1;
    end
    wrDomain.full.next = ((
      wrDomain.wrPtr.current[PTR_W-1] !=
      wrDomain.rdPtr.current[PTR_W-1] ) & (
      wrDomain.wrPtr.current[PTR_W-2:0] >=
      wrDomain.rdPtr.current[PTR_W-2:0]
    ));
  end
  assign wr.full = wrDomain.full.current;
  assign ramWr.addr = wrDomain.wrPtr.current;


  assign rdDomain.clk = rd.clk;
  always_ff @(posedge rd.clk or negedge rst_n) begin
    if(!rst_n) begin
      rdDomain.wrPtr.current <= 0;
      rdDomain.rdPtr.current <= 0;
      rdDomain.empty.current <= 1;
      rdDomain.gray <= {'0, '0};
    end else begin
      rdDomain.wrPtr.current <= rdDomain.wrPtr.next;
      rdDomain.rdPtr.current <= rdDomain.rdPtr.next;
      rdDomain.empty.current <= rdDomain.empty.next;
      rdDomain.gray[0] <= wrDomain.wrPtr.current ^ (wrDomain.wrPtr.current >> 1);
      rdDomain.gray[1] <= rdDomain.gray[0];
    end
  end
  always_comb begin
    for(int i=PTR_W-1; i>=0; i--) begin
      if(i == PTR_W-1)
        rdDomain.wrPtr.next[i] = rdDomain.gray[1][i];
      else
        rdDomain.wrPtr.next[i] = rdDomain.wrPtr.next[i+1] ^ rdDomain.gray[1][i];
    end
    rdDomain.rdPtr.next = rdDomain.rdPtr.current;
    ramRd.en = 0;

    if(rd.en & !rd.empty) begin
      rdDomain.rdPtr.next ++;
      ramRd.en = 1;
    end
    rdDomain.empty.next =  rdDomain.wrPtr.current == rdDomain.rdPtr.next;
  end
  assign rd.empty = rdDomain.empty.current;
  assign ramRd.addr = rdDomain.rdPtr.current;

endmodule
