const std = @import("std");
const lx = @import("./lexer.zig");
const tkz = @import("./tokenizer.zig");

pub fn main() !void {
    std.debug.print("main running \n", .{});
}

test {
    const input = "=+(){},;";
    const expected: []tkz.Token = .{
        .{ tkz.TokenType.assign, "=" },
        .{ tkz.TokenType.plus, "+" },
        .{ tkz.TokenType.lparent, "(" },
        .{ tkz.TokenType.rparent, ")" },
        .{ tkz.TokenType.lbrace, "{" },
        .{ tkz.TokenType.rbrace, "}" },
        .{ tkz.TokenType.comma, "," },
        .{ tkz.TokenType.semicolon, ";" },
    };

    const lex: lx.Lexer = .{
        .input = input,
    };

    lx.readChar(&lex);

    for (expected) |test_token| {
        const currTok = lx.Lexer.nextToken(&lex);
        std.testing.expect(currTok.literal[0] == test_token.literal and currTok.type == test_token.type);
    }
}
