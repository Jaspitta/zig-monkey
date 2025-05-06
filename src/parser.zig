const std = @import("std");
const lxr = @import("./lexer.zig");
const ast = @import("./ast.zig");
const tkz = @import("./tokenizer.zig");

pub const Parser = struct {
    lexer: lxr.Lexer,
    curToken: tkz.Token,
    peekToken: tkz.Token,
    errors: *std.ArrayList([]const u8),

    pub const ExpTypes = enum {
        LOWEST,
        EQUALS,
        LESSGREATER,
        SUM,
        PRODUCT,
        PREFIX,
        CALL,
    };

    pub fn init(lexer: lxr.Lexer, allocator: std.mem.Allocator) !Parser {
        const errors = try allocator.create(std.ArrayList([]const u8));
        errors.* = std.ArrayList([]const u8).init(allocator);
        var parser = Parser{
            .lexer = lexer,
            .curToken = undefined,
            .peekToken = undefined,
            .errors = errors,
        };

        // setting both current and next token
        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    fn nextToken(self: *Parser) void {
        self.curToken = self.peekToken;
        self.peekToken = self.lexer.nextToken();
    }

    pub fn parseProgram(self: *Parser, allocator: std.mem.Allocator) !ast.Program {
        var program = ast.Program{ .statements = std.ArrayList(ast.Statement).init(allocator) };

        // could also use @as here, if there is an impactful difference in speed/memory
        while (@intFromEnum(self.curToken) != @intFromEnum(tkz.TokenTag.eof)) {
            const statement = self.parseStatement();
            if (statement != null) {
                try program.statements.append(statement.?);
            }
            self.nextToken();
        }
        return program;
    }

    fn parseStatement(self: *Parser) ?ast.Statement {
        return switch (self.curToken) {
            .let => return self.parseLetStatement(),
            .@"return" => return self.parseReturnStatement(),
            else => return ast.Statement{ .expression_statement = self.parseExpressionStatement() },
        };
    }

    fn parseExpression(self: Parser, precedence: Parser.ExpTypes) ?ast.Expression {
        _ = precedence;
        // maybe I sould build the expression inside prefixParse
        const idnt = self.curToken.prefixParse(self);
        if (idnt == null) return null;
        return ast.Expression{ .identifier = idnt.? };
    }

    fn parseExpressionStatement(self: *Parser) ast.ExpressionStatement {
        const stmnt = ast.ExpressionStatement{ .token = self.curToken, .expression = self.parseExpression(ExpTypes.LOWEST) orelse undefined };

        if (self.peekTokenIs(tkz.TokenTag.semicolon)) self.nextToken();
        return stmnt;
    }

    fn parseLetStatement(self: *Parser) ?ast.Statement {
        var stmnt = ast.Statement{ .letStatement = ast.LetStatement{
            .token = self.curToken,
            .name = undefined,
            .value = undefined,
        } };

        if (!self.expectPeek(tkz.TokenTag.ident)) return null;

        stmnt.letStatement.name = ast.Identifier{
            .token = self.curToken,
        };

        if (!self.expectPeek(tkz.TokenTag.assign)) return null;

        while (!self.curTokenIs(tkz.TokenTag.semicolon)) self.nextToken();
        return stmnt;
    }

    fn parseReturnStatement(self: *Parser) ?ast.Statement {
        const stmnt = ast.Statement{ .return_statement = ast.ReturnStatement{
            .token = self.curToken,
            .return_value = undefined,
        } };

        self.nextToken();
        // parse expression

        while (!self.curTokenIs(tkz.TokenTag.semicolon)) self.nextToken();
        return stmnt;
    }

    fn curTokenIs(self: Parser, tokenTag: tkz.TokenTag) bool {
        const actualEnum: tkz.TokenTag = @enumFromInt(@intFromEnum(self.curToken));
        return actualEnum == tokenTag;
    }

    fn peekTokenIs(self: Parser, tokenTag: tkz.TokenTag) bool {
        const actualEnum: tkz.TokenTag = @enumFromInt(@intFromEnum(self.peekToken));
        return actualEnum == tokenTag;
    }

    fn expectPeek(self: *Parser, tokenTag: tkz.TokenTag) bool {
        if (self.peekTokenIs(tokenTag)) {
            self.nextToken();
            return true;
        } else {
            self.peekErr(tokenTag) catch |err| {
                std.debug.print("{}\n", .{err});
            };
            return false;
        }
    }

    fn peekErr(self: *Parser, expected: tkz.TokenTag) !void {
        const curr_tag: tkz.TokenTag = @enumFromInt(@intFromEnum(self.peekToken));
        try self.errors.*.append(try std.fmt.allocPrint(self.errors.*.allocator, "expected tag was {} but found {}", .{ expected, curr_tag }));
    }

    // fn prefixParseFn(self: Parser, token: tkz.Token) ast.Expression {}
    // fn infixParseFn(self: Parser, left_side: ast.Expression, token: tkz.Token) ast.Expression {}
};

test {
    const input =
        \\ let x = 5;
        \\ let y = 10;
        \\ let foobar = 838383;
    ;

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const g_allocator = arena_allocator.allocator();

    const lex = lxr.Lexer.init(input);
    var prs = try Parser.init(lex, g_allocator);

    const program = try prs.parseProgram(g_allocator);
    if (program.statements.items.len != 3) try std.testing.expect(false);

    const expected = [_][]const u8{ "x", "y", "foobar" };

    for (expected, 0..) |expect, i| try testLetStatement(program.statements.items[i], expect);
    try checkParseErrors(prs);
}

test {
    const input = "foobar;";

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const g_allocator = arena_allocator.allocator();

    var prs = try Parser.init(lxr.Lexer.init(input), g_allocator);
    const program = try prs.parseProgram(g_allocator);
    try checkParseErrors(prs);
    try std.testing.expect(program.statements.items.len == 1);
    const stmn = program.statements.items[0].expression_statement;
    const ident = stmn.expression.identifier;
    try std.testing.expect(std.mem.eql(u8, ident.tokenLiteral(), "foobar"));
    try std.testing.expect(std.mem.eql(u8, ident.token.ident, "foobar"));
}

test {
    const input =
        \\ return 5;
        \\ return 10;
        \\ return 838383;
    ;

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const g_allocator = arena_allocator.allocator();

    const lex = lxr.Lexer.init(input);
    var prs = try Parser.init(lex, g_allocator);

    const program = try prs.parseProgram(g_allocator);
    if (program.statements.items.len != 3) try std.testing.expect(false);

    for (program.statements.items) |stmnt| try std.testing.expect(std.mem.eql(u8, stmnt.tokenLiteral(), "return"));
    try checkParseErrors(prs);
}

test {
    var expected_program = ast.Program{
        .statements = undefined,
    };
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const g_allocator = arena_allocator.allocator();

    var list = std.ArrayList(ast.Statement).init(g_allocator);
    defer list.deinit();
    try list.append(ast.Statement{ .letStatement = ast.LetStatement{ .token = tkz.Token{ .let = "let" }, .name = ast.Identifier{
        .token = tkz.Token{ .ident = "myVar" },
    }, .value = ast.Expression{
        .identifier = ast.Identifier{ .token = tkz.Token{ .ident = "anotherVar" } },
    } } });

    expected_program.statements = list;

    // could create the buffer here and pass it instead of allocating on heap
    try std.testing.expect(std.mem.eql(u8, expected_program.toStr(g_allocator), "let myVar = anotherVar;"));
}

fn testLetStatement(stmnt: ast.Statement, expect: []const u8) !void {
    try std.testing.expect(std.mem.eql(u8, stmnt.tokenLiteral(), "let"));
    // switch (stmnt) {
    //     .letStatement => {},
    //     .return_statement => {},
    //     // else => std.testing.expect(false),
    // }

    try std.testing.expect(std.mem.eql(u8, stmnt.letStatement.name.tokenLiteral(), expect));
    // try std.testing.expect(std.mem.eql(u8, stmnt.letStatement.token.let, expect));
}

fn checkParseErrors(parser: Parser) !void {
    if (parser.errors.*.items.len > 0) {
        for (parser.errors.*.items) |err| {
            std.debug.print("{s}", .{err});
            std.debug.print("\n", .{});
        }
    }
    try std.testing.expect(parser.errors.*.items.len == 0);
}
