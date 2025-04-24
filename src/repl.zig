const std = @import("std");
const lx = @import("./lexer.zig");
const tk = @import("./tokenizer.zig");

const prompt = ">> ";

pub fn start(reader: std.io.AnyReader, writer: std.io.AnyWriter) !void {
    while (true) {
        try writer.print(prompt, .{});
        var buffer: [1024]u8 = undefined;
        const line = reader.readUntilDelimiter(&buffer, '\n') catch |err| {
            if (err == error.EndOfStream) {
                return;
            } else return err;
        };
        if (line.len == 0) continue;
        var lexer: lx.Lexer = lx.Lexer.init(line);
        var token = try lexer.nextToken();
        while (token != tk.TokenTag.eof) : (token = try lexer.nextToken()) {
            try writer.print("{}\n", .{token});
        }
    }
}

test {
    var input_stream = std.io.fixedBufferStream("let five = 5;\n");
    var output_stream = std.ArrayList(u8).init(std.testing.allocator);
    defer output_stream.deinit();
    try start(input_stream.reader().any(), output_stream.writer().any());
    const expected =
        \\>> tokenizer.Token{ .let = { 108, 101, 116 } }
        \\tokenizer.Token{ .ident = { 102, 105, 118, 101 } }
        \\tokenizer.Token{ .assign = 61 }
        \\tokenizer.Token{ .int = { 53 } }
        \\tokenizer.Token{ .semicolon = 59 }
        \\>> 
    ;
    for (output_stream.items, 0..) |item, i| if (item != expected[i]) try std.testing.expect(false);
}
