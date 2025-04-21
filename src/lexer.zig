const std = @import("std");
const tkz = @import("./tokenizer.zig");

pub const Lexer = struct {
    input: []const u8,
    position: u32,
    read_position: u32,
    ch: u8,

    const Self = @This();

    pub fn init(input: []const u8) Lexer {
        var lexer = Lexer{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = input[0],
        };
        lexer.readChar();

        return lexer;
    }

    pub fn readChar(self: *Self) void {
        self.ch = if (self.read_position >= self.input.len) 0 else self.input[self.read_position];
        self.position = self.read_position;
        self.read_position += 1;
    }

    pub fn nextToken(self: *Self) tkz.unimplementedTokenError!tkz.Token {
        const token = switch (self.ch) {
            '=' => tkz.Token{ .assign = self.ch },
            ';' => tkz.Token{ .semicolon = self.ch },
            '(' => tkz.Token{ .lparent = self.ch },
            ')' => tkz.Token{ .rparent = self.ch },
            ',' => tkz.Token{ .comma = self.ch },
            '+' => tkz.Token{ .plus = self.ch },
            '{' => tkz.Token{ .lbrace = self.ch },
            '}' => tkz.Token{ .rbrace = self.ch },
            0 => tkz.Token{ .eof = self.ch },
            else => {
                if (isLetter(self.ch)) {
                    return tkz.Token{ .ident = self.readIdentifier() };
                } else {
                    return tkz.Token{ .illegal = self.ch };
                }
            },
        };
        self.readChar();
        return token;
    }

    pub fn readIdentifier(self: *Self) []const u8 {
        const start_pos = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }
        return self.input[start_pos..self.position];
    }

    fn isLetter(character: u8) bool {
        return (character >= 65 and character <= 90) or (character >= 97 and character <= 122) or (character == '_');
    }
};
