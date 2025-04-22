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

test {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\let result = add(five, ten);
        \\
    ;

    var expected: [37]tkz.Token = undefined;
    expected[0] = tkz.Token{ .let = "let" };
    expected[1] = tkz.Token{ .ident = "five" };
    expected[2] = tkz.Token{ .assign = '=' };
    expected[3] = tkz.Token{ .int = "5" };
    expected[4] = tkz.Token{ .semicolon = ';' };
    expected[5] = tkz.Token{ .let = "let" };
    expected[6] = tkz.Token{ .ident = "ten" };
    expected[7] = tkz.Token{ .assign = '=' };
    expected[8] = tkz.Token{ .int = "10" };
    expected[9] = tkz.Token{ .semicolon = ';' };
    expected[10] = tkz.Token{ .let = "let" };
    expected[11] = tkz.Token{ .ident = "add" };
    expected[12] = tkz.Token{ .assign = '=' };
    expected[13] = tkz.Token{ .function = "fn" };
    expected[14] = tkz.Token{ .lparent = '(' };
    expected[15] = tkz.Token{ .ident = "x" };
    expected[16] = tkz.Token{ .comma = ',' };
    expected[17] = tkz.Token{ .ident = "y" };
    expected[18] = tkz.Token{ .rparent = ')' };
    expected[19] = tkz.Token{ .lbrace = '{' };
    expected[20] = tkz.Token{ .ident = "x" };
    expected[21] = tkz.Token{ .plus = '+' };
    expected[22] = tkz.Token{ .ident = "y" };
    expected[23] = tkz.Token{ .semicolon = ';' };
    expected[24] = tkz.Token{ .rbrace = '}' };
    expected[25] = tkz.Token{ .semicolon = ';' };
    expected[26] = tkz.Token{ .let = "let" };
    expected[27] = tkz.Token{ .ident = "result" };
    expected[28] = tkz.Token{ .assign = '=' };
    expected[29] = tkz.Token{ .ident = "add" };
    expected[30] = tkz.Token{ .lparent = '(' };
    expected[31] = tkz.Token{ .ident = "five" };
    expected[32] = tkz.Token{ .comma = ',' };
    expected[33] = tkz.Token{ .ident = "ten" };
    expected[34] = tkz.Token{ .rparent = ')' };
    expected[35] = tkz.Token{ .semicolon = ';' };
    expected[36] = tkz.Token{ .eof = 0 };

    var lexer = lx.Lexer.init(input);
    for (expected) |expect| {
        const token = try lexer.nextToken();
        try std.testing.expectEqualDeep(expect, token);
    }
}
