const tkz = @import("./tokenizer.zig");

// too early to think about the layout in memory for me: https://vimeo.com/649009599
const Lexer = struct {
    input: []u8,
    position: u32,
    readPosition: u32,
    ch: u8,
};

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

    const lex: Lexer = .{
        .input = input,
    };
}
