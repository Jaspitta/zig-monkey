const std = @import("std");
const tkz = @import("./tokenizer.zig");

const Node = union(enum) {
    statement: Statement,
    expression: Expression,

    pub fn tokenLiteral(self: Node) []const u8 {
        switch (self) {
            inline else => |case| return case.tokenLiteral(),
        }
    }

    pub fn toStr(self: Node) []const u8 {
        switch (self) {
            inline else => |case| return case.toStr(),
        }
    }
};

// const StatementU = union(enum) {
//     pub fn statementNode(self: StatementU) []const u8 {
//         switch (self) {
//             inline else => |case| return case.statementNode(),
//         }
//     }
// };

pub const Statement = union(enum) {
    letStatement: LetStatement,
    return_statement: ReturnStatement,
    expression_statement: ExpressionStatement,

    pub fn tokenLiteral(self: Statement) []const u8 {
        switch (self) {
            inline else => |case| return case.tokenLiteral(),
        }
    }

    pub fn toStr(self: Statement) []const u8 {
        switch (self) {
            inline else => |case| return case.toStr(),
        }
    }
};

// const ExpressionU = union(enum) {
//     identifier: Identifier,
//
//     pub fn expressionNode(self: Node) []const u8 {
//         switch (self) {
//             inline else => |case| return case.tokenLiteral(),
//         }
//     }
// };

const Expression = union(enum) {
    identifier: Identifier,

    pub fn tokenLiteral(self: Expression) []const u8 {
        switch (self) {
            inline else => |case| return case.tokenLiteral(),
        }
    }

    pub fn toStr(self: Expression) []const u8 {
        switch (self) {
            inline else => |case| return case.toStr(),
        }
    }
};

// root of the AST
pub const Program = struct {
    statements: std.ArrayList(Statement),

    fn tokenLiteral(self: Program) []const u8 {
        return if (self.statements.len > 0) self.statements[0].node.tokenLiteral() else return "";
    }

    pub fn toStr(self: Program) []const u8 {
        // assuming max length
        var str: [1024]u8 = undefined;
        var i: u16 = 0;
        for (self.statements.items) |item| {
            for (item.toStr()) |ch| {
                str[i] = ch;
                i += 1;
            }
            str[i] = '\n';
            i += 1;
        }
        return str[0..i];
    }
};

pub const Identifier = struct {
    token: tkz.Token,

    pub fn tokenLiteral(self: Identifier) []const u8 {
        return self.token.ident;
    }

    pub fn toStr(self: Identifier) []const u8 {
        return self.token.ident;
    }
};

pub const LetStatement = struct {
    token: tkz.Token,
    name: Identifier,
    value: Expression,

    fn tokenLiteral(self: LetStatement) []const u8 {
        return self.token.let;
    }

    // need to check for undefined;
    pub fn toStr(self: LetStatement) []const u8 {
        var i: u16 = 0;
        //assuming max length
        var resp: [1024]u8 = undefined;
        for (self.token.literal()) |ch| {
            resp[i] = ch;
            i += 1;
        }
        resp[i] = ' ';
        i += 1;
        for (self.name.tokenLiteral()) |ch| {
            resp[i] = ch;
            i += 1;
        }
        resp[i] = ' ';
        i += 1;
        resp[i] = '=';
        i += 1;
        resp[i] = ' ';
        i += 1;
        for (self.value.toStr()) |ch| {
            resp[i] = ch;
            i += 1;
        }
        resp[i] = ';';
        i += 1;

        return resp[0..i];
    }
};

pub const ReturnStatement = struct {
    token: tkz.Token,
    return_value: Expression,

    fn tokenLiteral(self: ReturnStatement) []const u8 {
        return self.token.@"return";
    }

    pub fn toStr(self: ReturnStatement) []const u8 {
        var i: u16 = 0;
        //assume max length;
        var resp: [1024]u8 = undefined;
        for (self.token.literal()) |ch| {
            resp[i] = ch;
            i += 1;
        }
        resp[i] = ' ';
        i += 1;
        for (self.return_value.toStr()) |ch| {
            resp[i] = ch;
            i += 1;
        }
        resp[i] = ';';
        return resp[0..i];
    }
};

pub const ExpressionStatement = struct {
    token: tkz.Token,
    expression: Expression,

    fn tokenLiteral(self: ExpressionStatement) []const u8 {
        return self.token.literal();
    }

    pub fn toStr(self: ExpressionStatement) []const u8 {
        return self.expression.toStr();
    }
};

// the statement is the main interface,

//statement
//  node
//  -> LetStatement
//expression
//  node

//
// const TestTagged = union(enum) {
//     impl_tagged_1: ImplTagged1,
//     impl_tagged_2: ImplTagged2,
//
//     pub fn tagged(self: TestTagged) []const u8 {
//         switch (self) {
//             inline else => |case| return case.tagged(),
//         }
//     }
// };
//
// const ImplTagged1 = struct {
//     pub fn tagged(self: ImplTagged1) []const u8 {
//         _ = self;
//         return "from ImplTagged1";
//     }
// };
//
// const ImplTagged2 = struct {
//     pub fn tagged(self: ImplTagged2) []const u8 {
//         _ = self;
//         return "from ImplTagged2";
//     }
// };
//
// const TestVirtual = struct {
//     ptr: *anyopaque,
//     virtualFn: *const fn (*anyopaque) []const u8,
//
//     fn virtual(self: TestVirtual) []const u8 {
//         return self.virtualFn(self.ptr);
//     }
// };
//
// const ImplVirtual1 = struct {
//     pub fn virtual(ptr: *anyopaque) []const u8 {
//         const self: *ImplVirtual1 = @ptrCast(@alignCast(ptr));
//         _ = self;
//         return "from ImplVirtual1";
//     }
//
//     pub fn testVirtual(self: *ImplVirtual1) TestVirtual {
//         return .{
//             .ptr = self,
//             .virtualFn = ImplVirtual1.virtual,
//         };
//     }
// };
//
// const ImplVirtual2 = struct {
//     pub fn virtual(ptr: *anyopaque) []const u8 {
//         const self: *ImplVirtual2 = @ptrCast(@alignCast(ptr));
//         _ = self;
//         return "from ImplVirtual2";
//     }
//
//     pub fn testVirtual(self: *ImplVirtual2) TestVirtual {
//         return .{
//             .ptr = self,
//             .virtualFn = ImplVirtual2.virtual,
//         };
//     }
// };

// interfaces with tagged unions consistently outperformed the once with virtual functions here
// test {
//     var timeT = std.time.nanoTimestamp();
//     for (0..1000000) |i| {
//         _ = i;
//         var testTagged = TestTagged{ .impl_tagged_1 = undefined };
//         _ = testTagged.tagged();
//     }
//     timeT = std.time.nanoTimestamp() - timeT;
//
//     var timeV = std.time.nanoTimestamp();
//     for (0..1000000) |i| {
//         _ = i;
//         var impl1 = ImplVirtual1{};
//         const impl_impl1 = impl1.testVirtual();
//         _ = impl_impl1.virtual();
//     }
//     timeV = std.time.nanoTimestamp() - timeV;
//
//     std.debug.print("virtual time is {d}\n", .{timeV});
//     std.debug.print("tagged time is {d}\n", .{timeT});
//
//     const timeVf: f64 = @floatFromInt(timeV);
//     const timeTf: f64 = @floatFromInt(timeT);
//     std.debug.print("{d}%\n", .{timeVf / timeTf});
// }

// const Node = struct {
//     tokenLiteral: *const fn () []const u8,
// };
//
// const Statement = struct {
//     node: Node,
//     statementNode: *const fn () Node,
// };
//
// const Expression = struct {
//     node: Node,
//     expressionNode: *const fn () Node,
// };
