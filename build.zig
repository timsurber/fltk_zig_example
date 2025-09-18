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

const example_sources = [_][]const u8{
    "examples/tree-simple.cxx",
    "examples/tree-custom-sort.cxx",
    "examples/animgifimage.cxx",
    "examples/animgifimage-play.cxx",
    "examples/animgifimage-resize.cxx",
    "examples/animgifimage-simple.cxx",
    "examples/browser-simple.cxx",
    // "examples/cairo-draw-x.cxx",
    "examples/callbacks.cxx",
    "examples/chart-simple.cxx",
    "examples/draggable-group.cxx",
    "examples/grid-simple.cxx",
    "examples/howto-add_fd-and-popen.cxx",
    "examples/howto-browser-with-icons.cxx",
    "examples/howto-drag-and-drop.cxx",
    "examples/howto-draw-an-x.cxx",
    "examples/howto-flex-simple.cxx",
    "examples/howto-menu-with-images.cxx",
    "examples/howto-parse-args.cxx",
    "examples/howto-remap-numpad-keyboard-keys.cxx",
    "examples/howto-simple-svg.cxx",
    "examples/howto-text-over-image-button.cxx",
    "examples/menubar-add.cxx",
    "examples/nativefilechooser-simple-app.cxx",
    "examples/nativefilechooser-simple.cxx",
    // "examples/OpenGL3-glut-test.cxx",
    // "examples/OpenGL3test.cxx",
    "examples/progress-simple.cxx",
    "examples/shapedwindow.cxx",
    "examples/simple-terminal.cxx",
    "examples/table-as-container.cxx",
    "examples/table-simple.cxx",
    "examples/table-sort.cxx",
    "examples/table-spreadsheet.cxx",
    "examples/table-spreadsheet-with-keyboard-nav.cxx",
    "examples/table-with-keynav.cxx",
    "examples/table-with-right-click-menu.cxx",
    "examples/table-with-right-column-stretch-fit.cxx",
    "examples/tabs-simple.cxx",
    "examples/textdisplay-with-colors.cxx",
    "examples/texteditor-simple.cxx",
    "examples/texteditor-with-dynamic-colors.cxx",
    "examples/tree-as-container.cxx",
    "examples/tree-custom-draw-items.cxx",
    "examples/tree-of-tables.cxx",
    "examples/wizard-simple.cxx",
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

        exe.root_module.addIncludePath(fltk_sources.path("."));
        exe.root_module.addIncludePath(fltk_sources.path("src"));
        exe.root_module.addIncludePath(fltk_pkg.path("zig-config"));

        exe.root_module.addCSourceFile(.{
            .file = fltk_sources.path(source),
            .flags = &cxx_flags,
            .language = .cpp,
        });

        exe.linkLibrary(fltk_lib);
        for (system_libs) |syslib| {
            exe.linkSystemLibrary(syslib);
        }

        const install = b.addInstallArtifact(exe, .{});
        example_step.dependOn(&install.step);
    }
}
