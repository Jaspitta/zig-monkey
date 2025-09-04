const std = @import("std");
const ast = @import("./ast.zig");
const prs = @import("./parser.zig");

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

    // this could hold the value of u8 fields
    // i could than return a slice to/of this
    // var holder: [1]u8 = undefined;

    pub fn literal(self: Token) []const u8 {
        return switch (self) {
            .illegal => &[1]u8{self.illegal},
            .eof => &[1]u8{0},
            .ident => self.ident,
            .int => self.int,
            .assign => "=",
            .plus => "+",
            .minus => "-",
            .bang => "!",
            .asterisk => "*",
            .slash => "/",
            .lt => "<",
            .gt => ">",
            .comma => ",",
            .semicolon => ";",
            .lparent => "(",
            .rparent => ")",
            .lbrace => "{",
            .rbrace => "}",
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

    // define precedence in expressions
    pub fn precedence(self: Token) prs.Parser.ExpTypes {
        return switch (self) {
            .equal => prs.Parser.ExpTypes.EQUALS,
            .not_equal => prs.Parser.ExpTypes.EQUALS,
            .lt => prs.Parser.ExpTypes.LESSGREATER,
            .gt => prs.Parser.ExpTypes.LESSGREATER,
            .plus => prs.Parser.ExpTypes.SUM,
            .minus => prs.Parser.ExpTypes.SUM,
            .slash => prs.Parser.ExpTypes.PRODUCT,
            .asterisk => prs.Parser.ExpTypes.PRODUCT,
            else => prs.Parser.ExpTypes.LOWEST,
        };
    }

    pub fn isPrefixCandidate(self: Token) bool {
        return switch (self) {
            .ident,
            .int,
            .bang,
            .minus,
            .true,
            .false,
            .lparent,
            .@"if",
            => return true,
            else => return false,
        };
    }

    pub fn prefixParse(self: Token, parser: *prs.Parser) !?ast.Expression {
        return switch (self) {
            .ident => return {
                return ast.Expression{ .identifier = ast.Identifier{ .token = parser.curToken } };
            },
            .int => {
                var lit = ast.Expression{ .integer_literal = ast.IntegerLiteral{ .token = parser.curToken, .value = undefined } };
                const int = std.fmt.parseInt(u64, parser.curToken.int, 10) catch {
                    try parser.errors.*.append(try std.fmt.allocPrint(parser.errors.*.allocator, "could not parse {s} as u64", .{parser.curToken.int}));
                    return null;
                };

                lit.integer_literal.value = int;
                return lit;
            },
            .bang, .minus => {
                var expr = ast.Expression{
                    .prefix_expression = ast.PrefixExpression{
                        .token = parser.curToken,
                        .right = undefined,
                        .allocator = parser.allocator,
                    },
                };

                parser.nextToken();
                const right = try std.mem.Allocator.create(expr.prefix_expression.allocator, ast.Expression);
                right.* = parser.parseExpression(prs.Parser.ExpTypes.PREFIX) orelse undefined;
                expr.prefix_expression.right = right;
                return expr;
            },
            .true => {
                // std.debug.print("parsing a true", .{});
                return ast.Expression{ .boolean = ast.Boolean{ .token = parser.curToken, .value = true } };
            },
            .false => {
                // std.debug.print("parsing a false", .{});
                return ast.Expression{ .boolean = ast.Boolean{ .token = parser.curToken, .value = false } };
            },
            .lparent => {
                parser.nextToken();
                const exp = parser.parseExpression(prs.Parser.ExpTypes.LOWEST);
                if (parser.expectPeek(TokenTag.rparent)) return exp;

                return null;
            },
            .@"if" => {
                var expression = ast.IfExpression{
                    .token = undefined,
                    .condition = undefined,
                    .consequence = undefined,
                    .alternative = null,
                    .allocator = parser.allocator,
                };

                if (!parser.expectPeek(TokenTag.lparent)) return null;

                parser.nextToken();
                var condition = parser.parseExpression(prs.Parser.ExpTypes.LOWEST) orelse return null;
                expression.condition = &condition;

                if (!parser.expectPeek(TokenTag.rparent)) return null;
                if (!parser.expectPeek(TokenTag.lbrace)) return null;

                expression.consequence = try parser.parseBlockStatement();

                if (parser.peekTokenIs(TokenTag.@"else")) {
                    parser.nextToken();
                    if (!parser.expectPeek(TokenTag.lbrace)) return null;

                    expression.alternative = try parser.parseBlockStatement();
                }

                return ast.Expression{ .if_expression = expression };
            },
            else => return null,
        };
    }

    pub fn infixParse(self: Token, parser: *prs.Parser, left: *ast.Expression) !?ast.Expression {
        return switch (self) {
            .plus, .minus, .slash, .asterisk, .equal, .not_equal, .lt, .gt => {
                var expr = ast.Expression{
                    .infix_expression = ast.InfixExpression{
                        .token = parser.curToken,
                        // left is the integer_literal with the first five
                        .left = left,
                        .right = undefined,
                        .allocator = parser.allocator,
                    },
                };

                const prec = parser.curPrecedence();
                parser.nextToken(); //5;

                const right_alloc = try parser.allocator.create(ast.Expression); // this is the second left
                const right = parser.parseExpression(prec) orelse undefined;
                right_alloc.* = right;

                expr.infix_expression.right = right_alloc;

                return expr;
            },
            else => return null,
        };
    }

    pub fn isInfixCandidate(self: Token) bool {
        return switch (self) {
            .plus, .minus, .slash, .asterisk, .equal, .not_equal, .lt, .gt => return true,
            else => return false,
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
