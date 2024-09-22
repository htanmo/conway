const std = @import("std");
const conway = @import("conway.zig");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const process = std.process;

pub fn main() !void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    // zig fmt: off
    // Creates a window
    const window = sdl.SDL_CreateWindow(
        "Conway's Game of Life",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        conway.SCREEN_WIDTH,
        conway.SCREEN_HEIGHT,
        0
    ) orelse {
        std.debug.print("\x1b[31merror:\x1b[0m failed to create window\n", .{});
        process.exit(0);
    };
    // zig fmt: on
    defer sdl.SDL_DestroyWindow(window);

    // zig fmt: off
    // SDL Renderer
    const renderer = sdl.SDL_CreateRenderer(
        window,
        0,
        sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC
    ) orelse {
        std.debug.print("\x1b[31merror:\x1b[0m failed to create renderer\n", .{});
        process.exit(0);
    };
    // zig fmt: on
    defer sdl.SDL_DestroyRenderer(renderer);

    // initialized variable for later use
    const ticks_per_frame: c_uint = 1000 / conway.FPS;
    var framestart: c_uint = undefined;
    var frametime: c_int = undefined;
    var mousedown = false;

    // Game struct initialization
    var game = conway.Game.init(renderer);

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
            conway.BG.r,
            conway.BG.g,
            conway.BG.b,
            conway.BG.a,
        );
        // zig fmt: on

        _ = sdl.SDL_RenderClear(renderer);

        game.drawGrid();
        game.drawCells();

        if (game.t_alive == 0 and !game.paused) {
            game.toggle();
        }

        if (game.paused) {
            game.drawPauseBox();
            var x: c_int = undefined; // mouse_cur_x
            var y: c_int = undefined; // mouse_cur_y
            _ = sdl.SDL_GetMouseState(&x, &y);
            var i = @divFloor(x, conway.CELL_SIZE);
            var j = @divFloor(y, conway.CELL_SIZE);
            if (i >= conway.ROWS - 1) {
                i = conway.ROWS - 1;
            }
            if (i < 0) {
                i = 0;
            }
            if (j >= conway.COLS - 1) {
                j = conway.COLS - 1;
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
