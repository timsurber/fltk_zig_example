const std = @import("std");

const example_sources = [_][]const u8{
    "fltk/examples/tree-simple.cxx",
    "fltk/examples/animgifimage.cxx",
    "fltk/examples/table-sort.cxx",
    "fltk/examples/howto-simple-svg.cxx",
    //"fltk/examples/OpenGL3test.cxx",
    //"fltk/examples/cairo-draw-x.cxx",
};

fn exampleNameFromSource(source: []const u8) []const u8 {
    const base = std.fs.path.basename(source);
    if (std.mem.lastIndexOfScalar(u8, base, '.')) |dot| {
        return base[0..dot];
    }
    return base;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const fltk_pkg = b.dependency("fltk", .{
        .target = target,
        .optimize = optimize,
    });
    const fltk_lib = fltk_pkg.artifact("fltk");

    const cxx_flags = [_][]const u8{"-std=c++11"};

    const example_step = b.step("example", "Build example binaries");

    for (example_sources) |source| {
        const example_name = exampleNameFromSource(source);

        const exe = b.addExecutable(.{
            .name = example_name,
            .target = target,
            .optimize = optimize,
        });

        exe.linkLibC();
        exe.linkLibCpp();

        exe.root_module.addCSourceFile(.{
            .file = b.path(source),
            .flags = &cxx_flags,
            .language = .cpp,
        });

        exe.linkLibrary(fltk_lib);

        const install = b.addInstallArtifact(exe, .{});
        example_step.dependOn(&install.step);
    }
}
