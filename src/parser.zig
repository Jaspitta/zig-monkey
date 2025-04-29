const std = @import("std");
const lxr = @import("./lexer.zig");
const ast = @import("./ast.zig");
const tkz = @import("./tokenizer.zig");

const Parser = struct {
    lexer: lxr.Lexer,
    curToken: tkz.Token,
    peekToken: tkz.Token,

    pub fn init(lexer: lxr.Lexer) Parser {
        const parser = .{
            .lexer = lexer,
            .curToken = undefined,
            .peekToken = undefined,
        };

        // setting both current and next token
        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    fn nextToken(self: Parser) void {
        self.curToken = self.peekToken;
        self.peekToken = self.lexer.nextToken();
    }

    pub fn parseProgram(self: Parser, allocator: std.Allocator) ast.Program {
        const program = ast.Program{};
        program.statements.init(allocator);
        while (self.curToken != tkz.TokenTag.eof) {
            const statement = program.parseStatement();
            if (statement != null) program.statements.append(statement);
            self.nextToken();
        }
        return program;
    }

    fn parseStatement(self: Parser) ast.Statement {
        return switch (self.curToken) {
            .let => return self.parseLetStatement(),
            else => return null,
        };
    }
};

fn testLetStatement(stmnt: ast.Statement, expect: []const u8) void {
    std.testing.expect(std.mem.equal(stmnt.tokenLiteral(), "let"));
    switch (stmnt) {
        .letStatement => {},
        else => std.testing.expect(false),
    }

    std.testing.expect(std.mem.equal(stmnt.letStatement.name.value, expect));
    std.testing.expect(std.mem.equal(stmnt.letStatement.token.let, expect));
}

test {
    const input =
        \\ let x = 5;
        \\ let y = 10;
        \\ let foobar = 838383;
    ;

    const lex = lxr.Lexer.init(input);
    const prs = Parser.init(lex);
    const program = prs.parseProgram(std.heap.ArenaAllocator.init(std.heap.page_allocator));
    defer program.statements.deinit();
    if (program == null) std.testing.expect(false);
    if (program.statements.items.len != 3) std.testing.expect(false);

    var expected = [3]u8{};
    expected[0] = "x";
    expected[0] = "y";
    expected[0] = "foobar";

    for (expected, 0..) |expect, i| testLetStatement(program.statements.items[i], expect);
}
