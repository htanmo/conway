# Conway's Game of Life

This is a simple implementation of Conway's Game of Life written in Zig,
utilizing the SDL library for graphics rendering.

## Build Instructions

Make sure you have Zig installed on your system. If not, you can download and install it from the official Zig website.
Ensure SDL2 is installed on your system. You can install it using your package manager or download it from the SDL website.

- ### Clone this repository:

```bash
git clone https://github.com/htanmo/conway.git
```

- ### Navigate to the project directory:

```bash
cd conway
```

- ### Build the project using Zig:

```bash
zig build -Doptimize=ReleaseSafe
```

- ### Run the executable:

> [!NOTE]
> Executable will be found under ./zig-out/bin directory after compilation.

```bash
./conway
```

## Keybindings

```text
Spacebar: Start/Pause the simulation.
C / Middle Mouse: Clear the board (kill all cells).
Right Mouse: Changes cursor mode.
Left Mouse: Change Cell state.
Esc: Exit the game.
```

## [LICENSE](./LICENSE)
