const std = @import("std");

pub const TokenTag = enum {
    illegal,
    eof,
    ident,
    int,
    assign,
    plus,
    comma,
    semicolon,
    lparent,
    rparent,
    lbrace,
    rbrace,
    function,
    let,
};

pub const Token = union(TokenTag) {
    illegal: u8,
    eof: u8,
    ident: []const u8,
    int: []const u8,
    assign: u8,
    plus: u8,
    comma: u8,
    semicolon: u8,
    lparent: u8,
    rparent: u8,
    lbrace: u8,
    rbrace: u8,
    function: []const u8,
    let: []const u8,
};

pub const unimplementedTokenError = error{
    NotImplemented,
};

pub fn identifierToToken(identifier: []const u8) unimplementedTokenError!Token {
    const code = strToSum(identifier);
    return switch (code) {
        325 => Token{ .let = identifier },
        870 => Token{ .function = identifier },
        else => unimplementedTokenError.NotImplemented,
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
    const identifiers: [3][]const u8 = .{ "let", "function", "if" };
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
