const std = @import("std");

const linux_system_libs = [_][]const u8{
    "pthread",
    "dl",
    "m",
    "X11",
    "Xext",
    "GL",
    "GLU",
};

const windows_system_libs = [_][]const u8{
    "gdi32",
    "user32",
    "shell32",
    "ole32",
    "oleaut32",
    "uuid",
    "comctl32",
    "comdlg32",
    "advapi32",
    "ws2_32",
    "winspool",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const os_tag = target.result.os.tag;

    if (os_tag != .linux and os_tag != .windows) {
        @panic("zig build currently supports only Linux (X11) and Windows (WinAPI) targets");
    }

    const fltk_pkg = b.dependency("fltk", .{
        .target = target,
        .optimize = optimize,
    });
    const fltk_sources = b.dependency("fltk_sources", .{});
    const fltk_lib = fltk_pkg.artifact("fltk");

    const system_libs = switch (os_tag) {
        .linux => &linux_system_libs,
        .windows => &windows_system_libs,
        else => unreachable,
    };

    const cxx_flags = [_][]const u8{"-std=c++11"};

    const tree_simple = b.addExecutable(.{
        .name = "tree-simple",
        .target = target,
        .optimize = optimize,
    });

    tree_simple.linkLibC();
    tree_simple.linkLibCpp();

    tree_simple.root_module.addIncludePath(fltk_sources.path("."));
    tree_simple.root_module.addIncludePath(fltk_sources.path("src"));
    tree_simple.root_module.addIncludePath(fltk_sources.path("FL"));
    tree_simple.root_module.addIncludePath(fltk_pkg.path("zig-config"));

    tree_simple.root_module.addCSourceFile(.{
        .file = fltk_sources.path("examples/tree-simple.cxx"),
        .flags = &cxx_flags,
        .language = .cpp,
    });

    tree_simple.linkLibrary(fltk_lib);
    for (system_libs) |syslib| {
        tree_simple.linkSystemLibrary(syslib);
    }

    const tree_simple_install = b.addInstallArtifact(tree_simple, .{});
    const tree_simple_step = b.step("tree-simple", "Build the tree-simple example");
    tree_simple_step.dependOn(&tree_simple_install.step);
}
