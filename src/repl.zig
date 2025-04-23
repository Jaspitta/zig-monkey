const std = @import("std");
const lx = @import("./lexer.zig");
const tk = @import("./tokenizer.zig");

const prompt = ">> ";

fn start() void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    while (true) {
        try stdout.print(prompt, .{});
        var buffer: [1024]u8 = undefined;
        const line = try stdin.readUntilDelimiter(&buffer, '\n');
        const lexer: lx.Lexer = lx.Lexer.init(line);
        const token = try lexer.nextToken();
        while (std.meta.Tag(token) == tk.TokenTag.eof) : (token = try lexer.nextToken()) {
            try stdout.print("{}\n", .{token});
        }
    }
}

test {}
