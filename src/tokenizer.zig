const std = @import("std");

pub const TokenType = enum(u32) {
    illegal = StrTokenCode("ILLEGAL"),
    eof = StrTokenCode("EOF"),
    ident = StrTokenCode("IDENT"),
    int = StrTokenCode("INT"),
    assign = StrTokenCode("="),
    plus = StrTokenCode("+"),
    comma = StrTokenCode(","),
    semicolon = StrTokenCode(";"),
    lparent = StrTokenCode("("),
    rparent = StrTokenCode(")"),
    lbrace = StrTokenCode("{"),
    rbrace = StrTokenCode("}"),
    function = StrTokenCode("fn"),
    let = StrTokenCode("let"),

    pub const TokenNameTable = [@typeInfo(TokenType).@"enum".fields.len][:0]const u8{ "ILLEGAL", "EOF", "IDENT", "INT", "=", "+", ",", ";", "(", ")", "{", "}", "fn", "let" };

    inline fn StrTokenCode(tokenName: [:0]const u8) u32 {
        var sum: u32 = 0;
        for (tokenName) |ch| {
            sum += ch;
        }
        return sum;
    }

    pub fn str(self: TokenType) [:0]const u8 {
        return TokenNameTable[@intFromEnum(self)];
    }
};

pub const Token = struct {
    type: TokenType,
    literal: []const u8,

    pub fn init(token_type: TokenType, literal: []*const u8) *Token {
        return &.{
            .type = token_type,
            .literal = literal,
        };
    }
};

// quickly check if there are conflicts with the decided tokens
test {
    var codes: [TokenType.TokenNameTable.len]u32 = undefined;
    for (TokenType.TokenNameTable, 0..) |str, i| {
        var sum: u32 = 0;
        for (str) |ch| {
            sum += ch;
        }
        codes[i] = sum;
    }
    for (codes[0 .. codes.len - 1], 0..codes.len - 1) |code, i| {
        for (codes[i + 1 ..]) |sCode| {
            try std.testing.expect(code != sCode);
        }
    }
}
