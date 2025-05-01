const std = @import("std");
const lxr = @import("./lexer.zig");
const ast = @import("./ast.zig");
const tkz = @import("./tokenizer.zig");

const Parser = struct {
    lexer: lxr.Lexer,
    curToken: tkz.Token,
    peekToken: tkz.Token,

    pub fn init(lexer: lxr.Lexer) Parser {
        var parser = Parser{
            .lexer = lexer,
            .curToken = undefined,
            .peekToken = undefined,
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
            else => return null,
        };
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

        if (!self.curTokenIs(tkz.TokenTag.semicolon)) self.nextToken();
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
        } else return false;
    }
};

test {
    const input =
        \\ let x = 5;
        \\ let y = 10;
        \\ let foobar = 838383;
    ;

    const lex = lxr.Lexer.init(input);
    var prs = Parser.init(lex);

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const g_allocator = arena_allocator.allocator();
    const program = try prs.parseProgram(g_allocator);
    if (program.statements.items.len != 3) try std.testing.expect(false);

    const expected = [_][]const u8{ "x", "y", "foobar" };

    for (expected, 0..) |expect, i| try testLetStatement(program.statements.items[i], expect);
}

fn testLetStatement(stmnt: ast.Statement, expect: []const u8) !void {
    try std.testing.expect(std.mem.eql(u8, stmnt.tokenLiteral(), "let"));
    switch (stmnt) {
        .letStatement => {},
        // else => std.testing.expect(false),
    }

    try std.testing.expect(std.mem.eql(u8, stmnt.letStatement.name.tokenLiteral(), expect));
    // try std.testing.expect(std.mem.eql(u8, stmnt.letStatement.token.let, expect));
}
