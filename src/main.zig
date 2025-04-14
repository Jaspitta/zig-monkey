comptime {
    _ = @import("./tokenizer.zig");
}

const std = @import("std");
const lx = @import("./lexer.zig");
const tkz = @import("./tokenizer.zig");

pub fn main() !void {
    std.debug.print("main running \n", .{});
}

// test {
//     const input = "=+(){},;";
//     var expected: [input.len]tkz.Toke = undefined;
//     const expected = ([_]*tkz.Token{}) ** input.len;
//     for (input, 0..) |ch, i| {
//         expected[i] = tkz.Token.init(std.meta.stringToEnum(tkz.TokenType, ch), ch);
//     }
//     // const expected = [_]tkz.Token{
//     //     .{ tkz.TokenType.assign, "=" },
//     //     .{ tkz.TokenType.plus, "+" },
//     //     .{ tkz.TokenType.lparent, "(" },
//     //     .{ tkz.TokenType.rparent, ")" },
//     //     .{ tkz.TokenType.lbrace, "{" },
//     //     .{ tkz.TokenType.rbrace, "}" },
//     //     .{ tkz.TokenType.comma, "," },
//     //     .{ tkz.TokenType.semicolon, ";" },
//     // };
//
//     const lex = lx.Lexer.init(input);
//
//     for (expected) |test_token| {
//         const currTok = lx.Lexer.nextToken(&lex);
//         std.debug.print("test actually run \n", .{});
//         std.testing.expect(currTok.literal[0] == test_token.literal and currTok.type == test_token.type);
//     }
// }
