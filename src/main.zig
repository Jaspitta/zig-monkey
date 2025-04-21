comptime {
    _ = @import("./tokenizer.zig");
}

const std = @import("std");
const lx = @import("./lexer.zig");
const tkz = @import("./tokenizer.zig");

pub fn main() !void {
    std.debug.print("main running \n", .{});
}

test {
    const input = "=+(){},;";

    var expected: [input.len]tkz.Token = undefined;
    expected[0] = tkz.Token{ .assign = '=' };
    expected[1] = tkz.Token{ .plus = '+' };
    expected[2] = tkz.Token{ .lparent = '(' };
    expected[3] = tkz.Token{ .rparent = ')' };
    expected[4] = tkz.Token{ .lbrace = '{' };
    expected[5] = tkz.Token{ .rbrace = '}' };
    expected[6] = tkz.Token{ .comma = ',' };
    expected[7] = tkz.Token{ .semicolon = ';' };

    var lexer = lx.Lexer.init(input);
    for (expected) |exp| {
        const token = lexer.nextToken();
        try switch (exp) {
            .assign => std.testing.expect((try token).assign == exp.assign),
            .plus => std.testing.expect((try token).plus == exp.plus),
            .lparent => std.testing.expect((try token).lparent == exp.lparent),
            .rparent => std.testing.expect((try token).rparent == exp.rparent),
            .lbrace => std.testing.expect((try token).lbrace == exp.lbrace),
            .rbrace => std.testing.expect((try token).rbrace == exp.rbrace),
            .comma => std.testing.expect((try token).comma == exp.comma),
            .semicolon => std.testing.expect((try token).semicolon == exp.semicolon),
            else => return,
        };
    }
}
