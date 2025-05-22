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
    block_statement: BlockStatement,

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

const BlockStatement = struct {
    token: tkz.Token,
    statements: []Statement,
    allocator: std.mem.Allocator,

    fn tokenLiteral(self: BlockStatement) []const u8 {
        return self.token.literal();
    }

    fn toStr(self: BlockStatement) []const u8 {
        var capacity: usize = 1024;
        var length: usize = 0;

        var buffer = self.allocator.alloc(u8, capacity) catch return "";
        for (self.statements) |statement| {
            const statement_str = statement.toStr();
            if (length + statement_str.len > capacity) {
                capacity = capacity * 2;
                const ext_buffer = self.allocator.alloc(u8, capacity) catch return "";
                std.mem.copyForwards(u8, ext_buffer, buffer);
                self.allocator.destroy(buffer);
                buffer = ext_buffer;
            }
            std.mem.copyForwards(u8, buffer[length..], statement_str);
            length += statement_str.len;
        }

        return buffer[0..length];
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

pub const Expression = union(enum) {
    identifier: Identifier,
    integer_literal: IntegerLiteral,
    prefix_expression: PrefixExpression,
    infix_expression: InfixExpression,
    boolean: Boolean,
    if_expression: IfExpression,

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

pub const IfExpression = struct {
    token: tkz.Token,
    condition: *Expression,
    consequence: BlockStatement,
    alternative: ?BlockStatement,
    allocator: std.mem.Allocator,

    pub fn tokenLiteral(self: IfExpression) []const u8 {
        return self.token.literal();
    }

    pub fn toStr(self: IfExpression) []const u8 {
        var i: usize = 0;

        const condition_str = self.condition.*.toStr();
        const consequence_str = self.consequence.token.literal();
        const alternative_str: ?[]const u8 = if (self.alternative != null) self.alternative.?.toStr() else null;

        var size = 2 + condition_str.len + 1 + consequence_str.len;
        if (alternative_str != null) size = size + 5 + self.alternative.?.toStr().len;

        var buffer = self.allocator.alloc(u8, size) catch return "";
        std.mem.copyForwards(u8, buffer[i..], "if");
        i += 2;
        std.mem.copyForwards(u8, buffer[i..], consequence_str);
        i += consequence_str.len;
        if (alternative_str != null) {
            std.mem.copyForwards(u8, buffer[i..], "else ");
            i += 5;
            std.mem.copyForwards(u8, buffer[i..], alternative_str.?);
        }
        return buffer;
    }
};

pub const Boolean = struct {
    token: tkz.Token,
    value: bool,

    fn tokenLiteral(self: Boolean) []const u8 {
        return self.token.literal();
    }

    fn toStr(self: Boolean) []const u8 {
        if (self.value) return "true" else return "false";
    }
};

pub const InfixExpression = struct {
    token: tkz.Token,
    right: *Expression,
    left: *Expression,
    allocator: std.mem.Allocator,

    pub fn tokenLiteral(self: InfixExpression) []const u8 {
        return self.token.literal();
    }

    pub fn toStr(self: InfixExpression) []const u8 {
        var i: usize = 0;

        // strs to append for size
        const right_str = self.right.*.toStr();
        const operator_str = self.token.literal();
        const left_str = self.left.*.toStr();

        // buffer with fixed size
        var buffer = self.allocator.alloc(u8, 1 + left_str.len + 1 + operator_str.len + 1 + right_str.len + 1) catch return "";
        std.mem.copyForwards(u8, buffer[i..], "(");
        i += 1;
        std.mem.copyForwards(u8, buffer[i..], left_str);
        i += left_str.len;
        std.mem.copyForwards(u8, buffer[i..], " ");
        i += 1;
        std.mem.copyForwards(u8, buffer[i..], operator_str);
        i += operator_str.len;
        std.mem.copyForwards(u8, buffer[i..], " ");
        i += 1;
        std.mem.copyForwards(u8, buffer[i..], right_str);
        i += right_str.len;
        std.mem.copyForwards(u8, buffer[i..], ")");
        return buffer;
    }
};

pub const PrefixExpression = struct {
    token: tkz.Token,
    // operator: []const u8,
    right: *Expression,
    // size can not be know at compile time
    allocator: std.mem.Allocator,

    pub fn tokenLiteral(self: PrefixExpression) []const u8 {
        return self.token.literal();
    }

    pub fn toStr(self: PrefixExpression) []const u8 {
        var i: usize = 0;
        const right_str = self.right.*.toStr();
        const operator_str = self.token.literal();
        var buffer = self.allocator.alloc(u8, 1 + operator_str.len + right_str.len + 1) catch return "";
        std.mem.copyForwards(u8, buffer[i..], "(");
        i += 1;
        std.mem.copyForwards(u8, buffer[i..], operator_str);
        i += operator_str.len;
        std.mem.copyForwards(u8, buffer[i..], right_str);
        i += right_str.len;
        std.mem.copyForwards(u8, buffer[i..], ")");
        return buffer;
    }
};

pub const IntegerLiteral = struct {
    token: tkz.Token,
    value: u64,

    pub fn tokenLiteral(self: IntegerLiteral) []const u8 {
        return self.token.int;
    }

    pub fn toStr(self: IntegerLiteral) []const u8 {
        return self.token.int;
    }
};

// root of the AST
pub const Program = struct {
    statements: std.ArrayList(Statement),

    fn tokenLiteral(self: Program) []const u8 {
        return if (self.statements.len > 0) self.statements[0].node.tokenLiteral() else return "";
    }

    pub fn toStr(self: Program, allocator: std.mem.Allocator) []const u8 {
        const size = sz: {
            var size: usize = 0;
            for (self.statements.items) |item| {
                size += item.toStr().len;
            }
            break :sz size;
        };
        var buffer = allocator.alloc(u8, size) catch return "";
        var i: usize = 0;
        for (self.statements.items) |item| {
            const str = item.toStr();
            std.mem.copyForwards(u8, buffer[i..], str);
            i += str.len;
        }
        return buffer;
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

    // Why does this not get lost when return from the stack?
    // maybe because size is known at compile time but I am not sure
    pub fn toStr(self: LetStatement) []const u8 {
        var i: u16 = 0;
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
