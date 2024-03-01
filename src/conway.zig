const sdl = @import("sdl.zig");

// Constants
pub const SCREEN_WIDTH = 640;
pub const SCREEN_HEIGHT = 480;
pub const CELL_SIZE = 10;
pub const ROWS = SCREEN_WIDTH / CELL_SIZE;
pub const COLS = SCREEN_HEIGHT / CELL_SIZE;
pub const FPS = 30;

// Color struct
const Color = struct {
    r: u8, // red
    g: u8, // green
    b: u8, // blue
    a: u8, // alpha
};

// Color for alive cells
const ALIVE = Color{
    .r = 45,
    .g = 198,
    .b = 83,
    .a = 0xff,
};

// Color for grid lines
const LINES = Color{
    .r = 233,
    .g = 236,
    .b = 239,
    .a = 0xff,
};

// Background color
pub const BG = Color{
    .r = 0xff,
    .g = 0xff,
    .b = 0xff,
    .a = 0xff,
};

// Cursor type
const CursorType = enum {
    death,
    birth,
};

// Game struct
pub const Game = struct {
    renderer: *sdl.SDL_Renderer, // SDL renderer
    grid: [ROWS][COLS]bool, // Grid
    next: [ROWS][COLS]bool, // Next grid
    gen: usize, // Generation
    t_alive: usize, // Total alive cell
    paused: bool, // Game state
    curtype: CursorType, // Cursor mode

    // Constructor
    pub fn init(renderer: *sdl.SDL_Renderer) Game {
        return Game{
            .renderer = renderer,
            .grid = [_][COLS]bool{[1]bool{false} ** COLS} ** ROWS,
            .next = [_][COLS]bool{[1]bool{false} ** COLS} ** ROWS,
            .gen = 0,
            .t_alive = 0,
            .paused = true,
            .curtype = .birth,
        };
    }

    // Clears the grid
    pub fn clear(self: *Game) void {
        self.grid = [_][COLS]bool{[1]bool{false} ** COLS} ** ROWS;
        self.gen = 0;
        self.t_alive = 0;
    }

    // Toggle game state
    pub fn toggle(self: *Game) void {
        self.paused = !self.paused;
    }

    // Draws the grid
    pub fn drawGrid(self: Game) void {
        // zig fmt: off
        // Grid color
        _ = sdl.SDL_SetRenderDrawColor(
            self.renderer,
            LINES.r,
            LINES.g,
            LINES.b,
            LINES.a,
        );
        // zig fmt: on
        var i: usize = 0;
        while (i < ROWS) : (i += 1) {
            var j: usize = 0;
            while (j < COLS) : (j += 1) {
                // zig fmt: off
                const box = sdl.SDL_Rect{
                    .x = @intCast(i * CELL_SIZE),
                    .y = @intCast(j * CELL_SIZE),
                    .w = CELL_SIZE,
                    .h = CELL_SIZE,
                };
                // zig fmt: on
                _ = sdl.SDL_RenderDrawRect(self.renderer, &box);
            }
        }
    }

    // Draws cursor
    pub fn drawCursor(self: Game, x: c_int, y: c_int) void {
        switch (self.curtype) {
            .death => {
                _ = sdl.SDL_SetRenderDrawColor(
                    self.renderer,
                    224,
                    30,
                    55,
                    0xff,
                );
            },
            .birth => {
                _ = sdl.SDL_SetRenderDrawColor(
                    self.renderer,
                    ALIVE.r,
                    ALIVE.g,
                    ALIVE.b,
                    0xff,
                );
            },
        }
        const box = sdl.SDL_Rect{
            .x = @intCast(x * CELL_SIZE),
            .y = @intCast(y * CELL_SIZE),
            .w = CELL_SIZE,
            .h = CELL_SIZE,
        };
        _ = sdl.SDL_RenderDrawRect(self.renderer, &box);
    }

    // Draws pause mode indicator
    pub fn drawPauseBox(self: Game) void {
        _ = sdl.SDL_SetRenderDrawColor(
            self.renderer,
            224,
            30,
            55,
            0xff,
        );
        const box = sdl.SDL_Rect{
            .x = @intCast(0),
            .y = @intCast(0),
            .w = SCREEN_WIDTH,
            .h = SCREEN_HEIGHT,
        };
        _ = sdl.SDL_RenderDrawRect(self.renderer, &box);
    }

    // Count numbers of alive neighbours of a cell
    fn countNeighbours(self: Game, x: usize, y: usize) u4 {
        var count: u4 = 0;

        // Dealing with edge cases (TT)
        var xmin: usize = undefined;
        var xmax: usize = undefined;
        var ymin: usize = undefined;
        var ymax: usize = undefined;
        if (x == 0) {
            xmin = 0;
        } else {
            xmin = x - 1;
        }
        if (x == ROWS - 1) {
            xmax = ROWS - 1;
        } else {
            xmax = x + 1;
        }
        if (y == 0) {
            ymin = 0;
        } else {
            ymin = y - 1;
        }
        if (y == COLS - 1) {
            ymax = COLS - 1;
        } else {
            ymax = y + 1;
        }

        var i: usize = xmin;
        while (i <= xmax) : (i += 1) {
            var j: usize = ymin;
            while (j <= ymax) : (j += 1) {
                if (self.grid[i][j]) {
                    if (i != x or j != y) {
                        count += 1;
                    }
                }
            }
        }
        return count;
    }

    // Draws alive cells in the grid
    pub fn drawCells(self: *Game) void {
        self.t_alive = 0;
        var i: usize = 0;
        while (i < ROWS) : (i += 1) {
            var j: usize = 0;
            while (j < COLS) : (j += 1) {
                if (self.grid[i][j]) {
                    // zig fmt: off
                    const cell = sdl.SDL_Rect{
                        .x = @intCast(i * CELL_SIZE),
                        .y = @intCast(j * CELL_SIZE),
                        .w = CELL_SIZE,
                        .h = CELL_SIZE
                    };
                    _ = sdl.SDL_SetRenderDrawColor(
                        self.renderer,
                        ALIVE.r,
                        ALIVE.g,
                        ALIVE.b,
                        ALIVE.a,
                    );
                    // zig fmt: on
                    _ = sdl.SDL_RenderFillRect(self.renderer, &cell);
                    self.t_alive += 1;
                }
            }
        }
    }

    // Change cursor mode
    pub fn changeCurMode(self: *Game) void {
        self.curtype = switch (self.curtype) {
            .death => .birth,
            .birth => .death,
        };
    }

    // Toggle cell state
    pub fn setState(self: *Game, x: usize, y: usize) void {
        if (self.paused and self.curtype == .birth) {
            self.grid[x][y] = true;
        } else if (self.paused and self.curtype == .death) {
            self.grid[x][y] = false;
        }
    }

    // Updates the grid state
    pub fn update(self: *Game) void {
        self.next = self.grid;
        var i: usize = 0;
        while (i < ROWS) : (i += 1) {
            var j: usize = 0;
            while (j < COLS) : (j += 1) {
                const alive = self.countNeighbours(i, j);
                if (!self.grid[i][j]) {
                    if (alive == 3) {
                        self.next[i][j] = true;
                    }
                } else {
                    if (alive != 2 and alive != 3) {
                        self.next[i][j] = false;
                    }
                }
            }
        }
        self.grid = self.next;
        self.gen +%= 1;
    }
};
