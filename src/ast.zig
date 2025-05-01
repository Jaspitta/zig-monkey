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

    pub fn tokenLiteral(self: Statement) []const u8 {
        switch (self) {
            inline else => |case| return case.tokenLiteral(),
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
    pub fn tokenLiteral(self: Expression) []const u8 {
        switch (self) {
            inline else => |case| return case.tokenLiteral(),
        }
    }
};

// root of the AST
pub const Program = struct {
    statements: std.ArrayList(Statement),

    // fn tokenLiteral(self: Program) []const u8 {
    //     return if (self.statements.len > 0) self.statements[0].node.tokenLiteral() else return "";
    // }

};

pub const Identifier = struct {
    token: tkz.Token,

    pub fn tokenLiteral(self: Identifier) []const u8 {
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
