pub const TokenType = enum([]u8) {
    illegal,
    eof,
    ident = ([_]u8{ 'I', 'D', 'E', 'N', 'T' })[0..],
    int,
    assign = "=",
    plus = "+",
    comma = ",",
    semicolon = ";",
    lparent = "(",
    rparent = ")",
    lbrace = "{",
    rbrace = "}",
    function,
    let,
};

pub const Token = struct {
    type: TokenType,
    literal: []u8,

    pub fn init(token_type: TokenType, literal: []u8) *Token {
        return &.{
            .type = token_type,
            .literal = literal,
        };
    }
};
