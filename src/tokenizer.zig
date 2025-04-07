pub const TokenType = enum([]u8) {
    illegal,
    eof,
    ident = "IDENT",
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
};
