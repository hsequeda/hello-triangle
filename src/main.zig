const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640, 480, "Hello, mach-glfw!", null, null, .{}) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;

    try gl.load(proc, glGetProcAddress);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        // inputs
        processInput(window);

        // other things
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // handling window refresh
        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn processInput(w: glfw.Window) void {
    if (w.getKey(glfw.Key.escape) == glfw.Action.press) {
        w.setShouldClose(true);
    }
}
