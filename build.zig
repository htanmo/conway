const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "life",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // SDL2
    const sdl_path = "./libs/SDL2/";
    const include = std.Build.LazyPath.relative(sdl_path ++ "include");
    exe.addIncludePath(include);
    if (builtin.target.cpu.arch == .x86_64) {
        const lib_path = std.Build.LazyPath.relative(sdl_path ++ "lib/x64");
        exe.addLibraryPath(lib_path);
        b.installBinFile(sdl_path ++ "lib/x64/SDL2.dll", "SDL2.dll");
    } else {
        const lib_path = std.Build.LazyPath.relative(sdl_path ++ "lib/x86");
        exe.addLibraryPath(lib_path);
        b.installBinFile(sdl_path ++ "lib/x86/SDL2.dll", "SDL2.dll");
    }
    exe.linkSystemLibrary("SDL2");
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_tests.step);
}
