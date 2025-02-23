
typedef struct {
  logic [8-1:0] data;
  logic sumDiffSel;
  logic load;
} x2zX_t;

typedef struct {
  logic [8-1:0] data;
  logic valid;
} x2zZ_t;

typedef struct {
  x2zX_t x;
  x2zZ_t z;
} x2zPort_t;


typedef struct {
  logic [8-1:0] data;
  logic load;
} z2yZ_t;

typedef struct {
  logic [8-1:0] data;
  logic valid;
} z2yY_t;

typedef struct {
  z2yZ_t z;
  z2yY_t y;
} z2yPort_t;
