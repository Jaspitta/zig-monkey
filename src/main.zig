comptime {
    _ = @import("./tokenizer.zig");
    _ = @import("./repl.zig");
    _ = @import("./ast.zig");
    _ = @import("./parser.zig");
}

const std = @import("std");
const lx = @import("./lexer.zig");
const tkz = @import("./tokenizer.zig");
const rpl = @import("./repl.zig");
const stdOut = std.io.getStdOut();
const stdIn = std.io.getStdIn();
const ast = @import("./ast.zig");

pub fn main() !void {
    std.debug.print("Hello user, welcome to the monkey language zig interpreter \n", .{});
    try rpl.start(stdIn.reader().any(), stdOut.writer().any());
}

test {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
        \\
    ;

    var expected: [74]tkz.Token = undefined;
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
    expected[36] = tkz.Token{ .bang = '!' };
    expected[37] = tkz.Token{ .minus = '-' };
    expected[38] = tkz.Token{ .slash = '/' };
    expected[39] = tkz.Token{ .asterisk = '*' };
    expected[40] = tkz.Token{ .int = "5" };
    expected[41] = tkz.Token{ .semicolon = ';' };
    expected[42] = tkz.Token{ .int = "5" };
    expected[43] = tkz.Token{ .lt = '<' };
    expected[44] = tkz.Token{ .int = "10" };
    expected[45] = tkz.Token{ .gt = '>' };
    expected[46] = tkz.Token{ .int = "5" };
    expected[47] = tkz.Token{ .semicolon = ';' };
    expected[48] = tkz.Token{ .@"if" = "if" };
    expected[49] = tkz.Token{ .lparent = '(' };
    expected[50] = tkz.Token{ .int = "5" };
    expected[51] = tkz.Token{ .lt = '<' };
    expected[52] = tkz.Token{ .int = "10" };
    expected[53] = tkz.Token{ .rparent = ')' };
    expected[54] = tkz.Token{ .lbrace = '{' };
    expected[55] = tkz.Token{ .@"return" = "return" };
    expected[56] = tkz.Token{ .true = "true" };
    expected[57] = tkz.Token{ .semicolon = ';' };
    expected[58] = tkz.Token{ .rbrace = '}' };
    expected[59] = tkz.Token{ .@"else" = "else" };
    expected[60] = tkz.Token{ .lbrace = '{' };
    expected[61] = tkz.Token{ .@"return" = "return" };
    expected[62] = tkz.Token{ .false = "false" };
    expected[63] = tkz.Token{ .semicolon = ';' };
    expected[64] = tkz.Token{ .rbrace = '}' };
    expected[65] = tkz.Token{ .int = "10" };
    expected[66] = tkz.Token{ .equal = "==" };
    expected[67] = tkz.Token{ .int = "10" };
    expected[68] = tkz.Token{ .semicolon = ';' };
    expected[69] = tkz.Token{ .int = "10" };
    expected[70] = tkz.Token{ .not_equal = "!=" };
    expected[71] = tkz.Token{ .int = "9" };
    expected[72] = tkz.Token{ .semicolon = ';' };
    expected[73] = tkz.Token{ .eof = 0 };

    var lexer = lx.Lexer.init(input);
    for (expected) |expect| {
        const token = lexer.nextToken();
        // std.debug.print("expected is {} actual is {}\n", .{ expect, token });
        try std.testing.expectEqualDeep(expect, token);
    }
}

// test {
//     const tag: tkz.Token = tkz.Token{ .let = "let" };
//     const enu: tkz.TokenTag = @as(tkz.TokenTag, tag);
//     std.debug.print("{}\n", .{enu});
//     std.debug.print("{any}", .{switch (tag) {
//         inline else => |case| case,
//     }});
// }

// test {
//     const TestEnum = enum {
//         foo,
//         bar,
//     };
//     const TestUnion = union(TestEnum) {
//         foo: []const u8,
//         bar: []const u8,
//     };
//
//     const testU_foo = TestUnion{ .foo = "test foo" };
//     const testU_bar = TestUnion{ .bar = "test bar" };
//
//     const p_foo = switch (testU_foo) {
//         inline else => |case| case,
//     };
//     const p_bar = switch (testU_bar) {
//         inline else => |case| case,
//     };
//
//     std.debug.print("for foo value is {s} and for bar value is {s}", .{ p_foo, p_bar });
// }
