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

    // Build and compile shareds program
    // Vertex Shader
    const vertexShaderSource: [*c]const u8 = @embedFile("vert.glsl");
    const vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, 1, &vertexShaderSource, 0);
    gl.compileShader(vertexShader);

    // Fragment Shader
    const fragmentShaderSource: [*c]const u8 = @embedFile("frag.glsl");
    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, 1, &fragmentShaderSource, 0);
    gl.compileShader(fragmentShader);

    // Create Program and link shaders to the program
    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);
    defer gl.deleteProgram(shaderProgram);
    // After sharers are linked to the program, we can delete them
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    // Initialize the VAO
    var vao: u32 = undefined;
    gl.genVertexArrays(1, &vao);
    defer gl.deleteVertexArrays(1, &vao);
    gl.bindVertexArray(vao);

    // Initialize the VBO
    const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
    var vbo: u32 = undefined;
    gl.genBuffers(1, &vbo);
    defer gl.deleteBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    // note that this is allowed, the call to glVertexAttribPointer registered
    // VBO as the vertex attribute's bound vertex buffer object so afterwards
    // we can safely unbind.
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);

    // You can unbind the VAO afterwards so other VAO calls won't accidentally
    // modify this VAO, but this rarely happens. Modifying other VAOs requires
    //a call to glBindVertexArray anyways so we generally don't unbind VAOs
    // (nor VBOs) when it's not directly necessary.
    gl.bindVertexArray(0);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        // inputs
        processInput(window);

        // other things
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw the Triangle
        gl.useProgram(shaderProgram);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

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
