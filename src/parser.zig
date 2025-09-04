const std = @import("std");
const lxr = @import("./lexer.zig");
const ast = @import("./ast.zig");
const tkz = @import("./tokenizer.zig");

pub const Parser = struct {
    lexer: lxr.Lexer,
    curToken: tkz.Token,
    peekToken: tkz.Token,
    errors: *std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

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
            .allocator = allocator,
        };

        // setting both current and next token
        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    pub fn nextToken(self: *Parser) void {
        self.curToken = self.peekToken;
        self.peekToken = self.lexer.nextToken();
    }

    pub fn parseProgram(self: *Parser) !ast.Program {
        var program = ast.Program{ .statements = std.ArrayList(ast.Statement).init(self.allocator) };

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

    pub fn parseExpression(self: *Parser, precedence: Parser.ExpTypes) ?ast.Expression {
        if (!self.curToken.isPrefixCandidate()) return null;

        // var because it needs to be swapped with the child, for infix expression
        var left_parent = self.allocator.create(ast.Expression) catch {
            return null;
        };

        left_parent.* = self.curToken.prefixParse(self) catch {
            self.errors.append(std.fmt.allocPrint(self.allocator, "no prefix parse function for {}", .{self.curToken}) catch {
                return null;
            }) catch {};
            return null;
        } orelse return null;

        while (!self.peekTokenIs(tkz.TokenTag.semicolon) and @intFromEnum(precedence) < @intFromEnum(self.peekPrecedence())) {
            if (!self.peekToken.isInfixCandidate()) return left_parent.*;

            self.nextToken();

            const left_child = self.allocator.create(ast.Expression) catch {
                return left_parent.*;
            };

            left_child.* = self.curToken.infixParse(self, left_parent) catch {
                return null;
            } orelse return null;

            // I am swapping the pointers not the content,
            // otherwise I would crete problems because the
            // parent is passed as left of the child above
            left_parent = left_child;
        }

        return left_parent.*;
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

    pub fn parseBlockStatement(self: *Parser) !ast.BlockStatement {
        var block = ast.BlockStatement{
            .token = self.curToken,
            .statements = undefined,
            .allocator = self.allocator,
        };

        block.statements = std.ArrayList(ast.Statement).init(block.allocator);

        self.nextToken();

        while (!self.curTokenIs(tkz.TokenTag.rbrace) and !self.curTokenIs(tkz.TokenTag.eof)) {
            const cur_stmnt = self.parseStatement() orelse {
                self.nextToken();
                continue;
            };
            try block.statements.append(cur_stmnt);
            self.nextToken();
        }

        return block;
    }

    fn curTokenIs(self: Parser, tokenTag: tkz.TokenTag) bool {
        const actualEnum: tkz.TokenTag = @enumFromInt(@intFromEnum(self.curToken));
        return actualEnum == tokenTag;
    }

    pub fn peekTokenIs(self: Parser, tokenTag: tkz.TokenTag) bool {
        const actualEnum: tkz.TokenTag = @enumFromInt(@intFromEnum(self.peekToken));
        return actualEnum == tokenTag;
    }

    pub fn expectPeek(self: *Parser, tokenTag: tkz.TokenTag) bool {
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

    pub fn peekPrecedence(self: Parser) ExpTypes {
        return self.peekToken.precedence();
    }

    pub fn curPrecedence(self: Parser) ExpTypes {
        return self.curToken.precedence();
    }
};

test {
    const input = "if (x < y) { x } else { y }";
    const lexer = lxr.Lexer.init(input);

    var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer a_alloc.deinit();
    const g_alloc = a_alloc.allocator();

    var parser = try Parser.init(lexer, g_alloc);
    const program = try parser.parseProgram();

    try std.testing.expect(program.statements.items.len == 1);

    const if_expression = program.statements.items[0].expression_statement.expression.if_expression;
    try testInfixExpression(if_expression.condition.*, []const u8, "x", "<", []const u8, "y");

    try std.testing.expect(if_expression.consequence.statements.items.len == 1);
    try testIdentifier(if_expression.consequence.statements.items[0].expression_statement.expression, "x");
    try std.testing.expect(if_expression.alternative != null);
}

test {
    const input = "if (x < y) { x }";
    const lexer = lxr.Lexer.init(input);

    var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer a_alloc.deinit();
    const g_alloc = a_alloc.allocator();

    var parser = try Parser.init(lexer, g_alloc);
    const program = try parser.parseProgram();

    try std.testing.expect(program.statements.items.len == 1);

    const if_expression = program.statements.items[0].expression_statement.expression.if_expression;
    try testInfixExpression(if_expression.condition.*, []const u8, "x", "<", []const u8, "y");

    try std.testing.expect(if_expression.consequence.statements.items.len == 1);
    try testIdentifier(if_expression.consequence.statements.items[0].expression_statement.expression, "x");
    try std.testing.expect(if_expression.alternative == null);
}

test {
    const Expected = struct { input: []const u8, operator: []const u8, value: bool };

    var expected: [2]Expected = undefined;
    expected[0] = Expected{
        .input = "!true;",
        .operator = "!",
        .value = true,
    };
    expected[1] = Expected{
        .input = "!false;",
        .operator = "!",
        .value = false,
    };

    var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer a_alloc.deinit();
    const g_alloc = a_alloc.allocator();
    for (expected) |expect| {
        const lexer = lxr.Lexer.init(expect.input);
        var parser = try Parser.init(lexer, g_alloc);
        const program = try parser.parseProgram();
        try checkParseErrors(parser);
        try std.testing.expect(program.statements.items.len == 1);
        const expr = program.statements.items[0].expression_statement;
        const prfx_expr = expr.expression.prefix_expression;
        try std.testing.expect(std.mem.eql(u8, prfx_expr.token.literal(), expect.operator));
        try std.testing.expect(prfx_expr.right.boolean.value == expect.value);
    }
}

test {
    const Expected = struct {
        input: []const u8,
        left: bool,
        operator: []const u8,
        right: bool,
    };

    var expected: [2]Expected = undefined;
    expected[0] = Expected{
        .input = "true == true",
        .left = true,
        .operator = "==",
        .right = true,
    };
    expected[1] = Expected{
        .input = "true != false",
        .left = true,
        .operator = "!=",
        .right = false,
    };

    for (expected) |expect| {
        // alloc init
        var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const g_alloc = a_alloc.allocator();
        defer a_alloc.deinit();

        // program parsing
        const l = lxr.Lexer.init(expect.input);
        var prs = try Parser.init(l, g_alloc);
        const prg = try prs.parseProgram();

        // checks
        try checkParseErrors(prs);
        try std.testing.expect(prg.statements.items.len == 1);

        // epxression
        const expr_stmnt = prg.statements.items[0].expression_statement;
        const inf_expr = expr_stmnt.expression.infix_expression;

        // test value
        try std.testing.expect(inf_expr.right.*.boolean.value == expect.right);
        try std.testing.expect(inf_expr.left.*.boolean.value == expect.left);

        // test operator
        try std.testing.expect(std.mem.eql(u8, inf_expr.token.literal(), expect.operator));
    }
}

test {
    const Expected = struct {
        input: []const u8,
        str: []const u8,
    };

    var expected: [5]Expected = undefined;
    expected[0] = Expected{
        .input = "true;",
        .str = "true",
    };
    expected[1] = Expected{
        .input = "false;",
        .str = "false",
    };
    expected[2] = Expected{
        .input = "3 > 5 == false;",
        .str = "((3 > 5) == false)",
    };
    expected[3] = Expected{
        .input = "3 < 5 == true;",
        .str = "((3 < 5) == true)",
    };
    expected[4] = Expected{
        .input = "!(true == true)",
        .str = "(!(true == true))",
    };

    for (expected) |expect| {
        // alloc init
        var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const g_alloc = a_alloc.allocator();
        defer a_alloc.deinit();

        // program parsing
        const l = lxr.Lexer.init(expect.input);
        var prs = try Parser.init(l, g_alloc);
        const prg = try prs.parseProgram();

        // checks
        try checkParseErrors(prs);
        try std.testing.expect(std.mem.eql(u8, prg.toStr(g_alloc), expect.str));
    }
}

test {
    const Expected = struct {
        input: []const u8,
        str: []const u8,
    };

    var expected: [8]Expected = undefined;

    expected[0] = Expected{
        .input = "-a * b",
        .str = "((-a) * b)",
    };
    expected[1] = Expected{
        .input = "!-a",
        .str = "(!(-a))",
    };
    expected[2] = Expected{
        .input = "3 + 4; -5 * 5",
        .str = "(3 + 4)((-5) * 5)",
    };
    expected[3] = Expected{
        .input = "5 > 4 == 3 < 4",
        .str = "((5 > 4) == (3 < 4))",
    };
    expected[4] = Expected{
        .input = "3 + 4 * 5 == 3 * 1 + 4 * 5",
        .str = "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))",
    };
    expected[5] = Expected{
        .input = "1 + (2 + 3) + 4",
        .str = "((1 + (2 + 3)) + 4)",
    };
    expected[6] = Expected{
        .input = "(5 + 5) * 2",
        .str = "((5 + 5) * 2)",
    };
    expected[7] = Expected{
        .input = "-(5 + 5)",
        .str = "(-(5 + 5))",
    };

    for (expected) |expect| {
        // alloc init
        var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const g_alloc = a_alloc.allocator();
        defer a_alloc.deinit();

        // program parsing
        const l = lxr.Lexer.init(expect.input);
        var prs = try Parser.init(l, g_alloc);
        const prg = try prs.parseProgram();

        // checks
        try checkParseErrors(prs);
        try std.testing.expect(std.mem.eql(u8, prg.toStr(g_alloc), expect.str));
    }
}

test {
    const Expected = struct {
        input: []const u8,
        left: u64,
        operator: []const u8,
        right: u64,
    };

    var expected: [8]Expected = undefined;
    expected[0] = Expected{
        .input = "5 + 5;",
        .left = 5,
        .operator = "+",
        .right = 5,
    };
    expected[1] = Expected{
        .input = "5 - 5;",
        .left = 5,
        .operator = "-",
        .right = 5,
    };
    expected[2] = Expected{
        .input = "5 * 5;",
        .left = 5,
        .operator = "*",
        .right = 5,
    };
    expected[3] = Expected{
        .input = "5 / 5;",
        .left = 5,
        .operator = "/",
        .right = 5,
    };
    expected[4] = Expected{
        .input = "5 > 5;",
        .left = 5,
        .operator = ">",
        .right = 5,
    };
    expected[5] = Expected{
        .input = "5 < 5;",
        .left = 5,
        .operator = "<",
        .right = 5,
    };
    expected[6] = Expected{
        .input = "5 == 5;",
        .left = 5,
        .operator = "==",
        .right = 5,
    };
    expected[7] = Expected{
        .input = "5 != 5;",
        .left = 5,
        .operator = "!=",
        .right = 5,
    };

    for (expected) |expect| {
        // alloc init
        var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const g_alloc = a_alloc.allocator();
        defer a_alloc.deinit();

        // program parsing
        const l = lxr.Lexer.init(expect.input);
        var prs = try Parser.init(l, g_alloc);
        const prg = try prs.parseProgram();

        // checks
        try checkParseErrors(prs);
        try std.testing.expect(prg.statements.items.len == 1);

        // epxression
        const expr_stmnt = prg.statements.items[0].expression_statement;
        const inf_expr = expr_stmnt.expression.infix_expression;

        // test value
        try std.testing.expect(inf_expr.right.*.integer_literal.value == expect.right);
        try std.testing.expect(inf_expr.left.*.integer_literal.value == expect.left);

        // test operator
        try std.testing.expect(std.mem.eql(u8, inf_expr.token.literal(), expect.operator));
    }
}

test {
    const Expected = struct { input: []const u8, operator: []const u8, integer_value: u64 };

    var expected: [2]Expected = undefined;
    expected[0] = Expected{
        .input = "!5;",
        .operator = "!",
        .integer_value = 5,
    };
    expected[1] = Expected{
        .input = "-15;",
        .operator = "-",
        .integer_value = 15,
    };

    var a_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer a_alloc.deinit();
    const g_alloc = a_alloc.allocator();
    for (expected) |expect| {
        const lexer = lxr.Lexer.init(expect.input);
        var parser = try Parser.init(lexer, g_alloc);
        const program = try parser.parseProgram();
        try checkParseErrors(parser);
        try std.testing.expect(program.statements.items.len == 1);
        const expr = program.statements.items[0].expression_statement;
        const prfx_expr = expr.expression.prefix_expression;
        try std.testing.expect(std.mem.eql(u8, prfx_expr.token.literal(), expect.operator));
        try std.testing.expect(prfx_expr.right.integer_literal.value == expect.integer_value);
    }
}

test {
    const input = "5;";
    const lex = lxr.Lexer.init(input);
    var page_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer page_allocator.deinit();
    const g_allocator = page_allocator.allocator();

    var prs = try Parser.init(lex, g_allocator);
    const prg = try prs.parseProgram();

    try std.testing.expect(prg.statements.items.len == 1);
    const expr_stmnt = prg.statements.items[0].expression_statement;
    const literal = expr_stmnt.expression.integer_literal;
    try std.testing.expect(literal.value == 5);
    try std.testing.expect(std.mem.eql(u8, literal.tokenLiteral(), "5"));
    try checkParseErrors(prs);
}

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

    const program = try prs.parseProgram();
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
    const program = try prs.parseProgram();
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

    const program = try prs.parseProgram();
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

fn testLiteralExp(comptime T: type, literal_exp: ast.Expression, value: T) !void {
    switch (literal_exp) {
        .identifier => if (T != []const u8) try std.testing.expect(false) else try testIdentifier(literal_exp, value),
        .integer_literal => if (T != u64) try std.testing.expect(false) else try testIntLiteral(literal_exp, value),
        .boolean => if (T != bool) try std.testing.expect(false) else try testBoolLiteral(literal_exp, value),
        else => try std.testing.expect(false),
    }
}

fn testBoolLiteral(boolean_exp: ast.Expression, value: bool) !void {
    try std.testing.expect(boolean_exp.boolean.value == value);
}

fn testInfixExpression(infix_exp: ast.Expression, comptime left_T: type, left: left_T, operator: []const u8, comptime right_T: type, right: right_T) !void {
    try testLiteralExp(left_T, infix_exp.infix_expression.left.*, left);
    try std.testing.expect(std.mem.eql(u8, infix_exp.tokenLiteral(), operator));
    try testLiteralExp(right_T, infix_exp.infix_expression.right.*, right);
}

fn testIdentifier(identifier_exp: ast.Expression, value: []const u8) !void {
    try std.testing.expect(std.mem.eql(u8, identifier_exp.identifier.tokenLiteral(), value));
}

fn testIntLiteral(int_literal: ast.Expression, value: u64) !void {
    try std.testing.expect(int_literal.integer_literal.value == value);
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
