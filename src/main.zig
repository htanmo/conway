const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

// Constants
const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = 480;
const CELL_SIZE = 10;
const ROWS = SCREEN_WIDTH / CELL_SIZE;
const COLS = SCREEN_HEIGHT / CELL_SIZE;
const FPS = 30;

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
const BG = Color{
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
const Game = struct {
    renderer: *sdl.SDL_Renderer, // SDL renderer
    grid: [ROWS][COLS]bool, // Grid
    next: [ROWS][COLS]bool, // Next grid
    gen: usize, // Generation
    t_alive: usize, // Total alive cell
    paused: bool, // Game state
    curtype: CursorType, // Cursor mode

    const Self = @This();

    // Constructor
    fn init(renderer: *sdl.SDL_Renderer) Self {
        return Self{
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
    fn clear(self: *Self) void {
        self.grid = [_][COLS]bool{[1]bool{false} ** COLS} ** ROWS;
        self.gen = 0;
        self.t_alive = 0;
    }

    // Toggle game state
    fn toggle(self: *Self) void {
        self.paused = !self.paused;
    }

    // Draws the grid
    fn drawGrid(self: Self) void {
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

    fn drawCursor(self: Self, x: c_int, y: c_int) void {
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

    // Count numbers of alive neighbours of a cell
    fn countNeighbours(self: Self, x: usize, y: usize) u4 {
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
    fn drawCells(self: *Self) void {
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
    fn changeCurMode(self: *Self) void {
        self.curtype = switch (self.curtype) {
            .death => .birth,
            .birth => .death,
        };
    }

    // Toggle cell state
    fn setState(self: *Self, x: usize, y: usize) void {
        if (self.paused and self.curtype == .birth) {
            self.grid[x][y] = true;
        } else if (self.paused and self.curtype == .death) {
            self.grid[x][y] = false;
        }
    }

    // Updates the grid state
    fn update(self: *Self) void {
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

pub fn main() !void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    // zig fmt: off
    // Creates a window
    const window = sdl.SDL_CreateWindow(
        "Conway's Game of Life",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        0
    );
    // zig fmt: on
    defer sdl.SDL_DestroyWindow(window);

    // zig fmt: off
    // SDL Renderer
    const renderer = sdl.SDL_CreateRenderer(
        window,
        0,
        sdl.SDL_RENDERER_PRESENTVSYNC
    );
    // zig fmt: on
    defer sdl.SDL_DestroyRenderer(renderer);

    // initialized variable for later use
    const ticks_per_frame: c_uint = 1000 / FPS;
    var framestart: c_uint = undefined;
    var frametime: c_int = undefined;
    var mousedown = false;

    var game = Game.init(renderer.?);

    mainloop: while (true) {
        framestart = sdl.SDL_GetTicks();
        var sdl_event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                sdl.SDL_QUIT => break :mainloop,
                sdl.SDL_MOUSEBUTTONDOWN => {
                    switch (sdl_event.button.button) {
                        sdl.SDL_BUTTON_RIGHT => {
                            if (game.paused)
                                game.changeCurMode();
                        },
                        sdl.SDL_BUTTON_LEFT => mousedown = true,
                        sdl.SDL_BUTTON_MIDDLE => {
                            if (game.paused)
                                game.clear();
                        },
                        else => {},
                    }
                },
                sdl.SDL_MOUSEBUTTONUP => {
                    mousedown = false;
                },
                sdl.SDL_KEYDOWN => {
                    switch (sdl_event.key.keysym.sym) {
                        sdl.SDLK_SPACE => game.toggle(),
                        sdl.SDLK_c => {
                            if (game.paused) {
                                game.clear();
                            }
                        },
                        sdl.SDLK_ESCAPE => break :mainloop,
                        else => {},
                    }
                },
                else => {},
            }
        }
        // zig fmt: off
        // BG color
        _ = sdl.SDL_SetRenderDrawColor(
            renderer,
            BG.r,
            BG.g,
            BG.b,
            BG.a,
        );
        // zig fmt: on

        _ = sdl.SDL_RenderClear(renderer);

        game.drawGrid();
        game.drawCells();

        if (game.paused) {
            var x: c_int = undefined; // mouse_cur_x
            var y: c_int = undefined; // mouse_cur_y
            _ = sdl.SDL_GetMouseState(&x, &y);
            var i = @divFloor(x, CELL_SIZE);
            var j = @divFloor(y, CELL_SIZE);
            if (i >= ROWS - 1) {
                i = ROWS - 1;
            }
            if (i < 0) {
                i = 0;
            }
            if (j >= COLS - 1) {
                j = COLS - 1;
            }
            if (j < 0) {
                j = 0;
            }
            game.drawCursor(i, j);
            if (mousedown) {
                game.setState(@intCast(i), @intCast(j));
            }
        }

        if (!game.paused) {
            game.update();
        }

        sdl.SDL_RenderPresent(renderer);
        frametime = @as(c_int, @intCast(sdl.SDL_GetTicks() - framestart));
        if (ticks_per_frame > frametime) {
            sdl.SDL_Delay(ticks_per_frame - @as(c_uint, @intCast(frametime)));
        }
    }
}
