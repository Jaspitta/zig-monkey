const std = @import("std");

pub const TokenTag = enum {
    illegal,
    eof,
    ident,
    int,
    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,
    lt,
    gt,
    comma,
    semicolon,
    lparent,
    rparent,
    lbrace,
    rbrace,
    function,
    let,
    @"if",
    @"return",
    @"else",
    true,
    false,
    equal,
    not_equal,
};

pub const Token = union(TokenTag) {
    illegal: u8,
    eof: u8,
    ident: []const u8,
    int: []const u8,
    assign: u8,
    plus: u8,
    minus: u8,
    bang: u8,
    asterisk: u8,
    slash: u8,
    lt: u8,
    gt: u8,
    comma: u8,
    semicolon: u8,
    lparent: u8,
    rparent: u8,
    lbrace: u8,
    rbrace: u8,
    function: []const u8,
    let: []const u8,
    @"if": []const u8,
    @"return": []const u8,
    @"else": []const u8,
    true: []const u8,
    false: []const u8,
    equal: []const u8,
    not_equal: []const u8,

    pub fn literal(self: Token) []const u8 {
        return switch (self) {
            .illegal => &[1]u8{self.illegal},
            .eof => &[1]u8{self.eof},
            .ident => self.ident,
            .int => self.int,
            .assign => &[1]u8{self.assign},
            .plus => &[1]u8{self.plus},
            .minus => &[1]u8{self.minus},
            .bang => &[1]u8{self.bang},
            .asterisk => &[1]u8{self.asterisk},
            .slash => &[1]u8{self.slash},
            .lt => &[1]u8{self.lt},
            .gt => &[1]u8{self.gt},
            .comma => &[1]u8{self.comma},
            .semicolon => &[1]u8{self.semicolon},
            .lparent => &[1]u8{self.lparent},
            .rparent => &[1]u8{self.rparent},
            .lbrace => &[1]u8{self.lbrace},
            .rbrace => &[1]u8{self.rbrace},
            .function => self.function,
            .let => self.let,
            .@"if" => self.@"if",
            .@"return" => self.@"return",
            .@"else" => self.@"else",
            .true => self.true,
            .false => self.false,
            .equal => self.equal,
            .not_equal => self.not_equal,
        };
    }
};

pub const unimplementedTokenError = error{
    NotImplemented,
};

pub fn identifierToToken(identifier: []const u8) Token {
    const code = strToSum(identifier);

    // This is probably is a good candidate for something done at comptime
    return switch (code) {
        325 => Token{ .let = identifier },
        870, 212 => Token{ .function = identifier },
        207 => Token{ .@"if" = identifier },
        672 => Token{ .@"return" = identifier },
        425 => Token{ .@"else" = identifier },
        448 => Token{ .true = identifier },
        523 => Token{ .false = identifier },
        else => Token{ .ident = identifier },
    };
}

fn strToSum(str: []const u8) u32 {
    var sum: u32 = 0;
    for (str) |ch| {
        sum += ch;
    }
    return sum;
}

test {
    const identifiers = [_][]const u8{ "let", "function", "fn", "if", "return", "else", "true", "false" };
    var codes: [identifiers.len]u32 = undefined;
    for (identifiers, 0..) |identifier, i| {
        codes[i] = strToSum(identifier);
    }

    // for (identifiers, 0..) |id, i| {
    //     std.debug.print("for identifier {s} code is {d}\n", .{ id, codes[i] });
    // }
    for (codes[0 .. codes.len - 1], 0..) |code, i| {
        for (codes[i + 1 ..]) |check| {
            try std.testing.expect(code != check);
        }
    }
}
