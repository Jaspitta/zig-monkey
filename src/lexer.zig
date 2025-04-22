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
        var token: tkz.Token = undefined;
        read: switch (self.ch) {
            '=' => token = tkz.Token{ .assign = self.ch },
            ';' => token = tkz.Token{ .semicolon = self.ch },
            '(' => token = tkz.Token{ .lparent = self.ch },
            ')' => token = tkz.Token{ .rparent = self.ch },
            ',' => token = tkz.Token{ .comma = self.ch },
            '+' => token = tkz.Token{ .plus = self.ch },
            '{' => token = tkz.Token{ .lbrace = self.ch },
            '}' => token = tkz.Token{ .rbrace = self.ch },
            0 => token = tkz.Token{ .eof = self.ch },
            else => {
                if (isLetter(self.ch)) {
                    // early termination because we already moved to the next char
                    return try tkz.identifierToToken(self.readIdentifier());
                } else if (isDigit(self.ch)) {
                    return tkz.Token{ .int = self.readNumber() };
                } else {
                    if (self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
                        self.readChar();
                        continue :read self.ch;
                    }
                    token = tkz.Token{ .illegal = self.ch };
                }
            },
        }

        self.readChar();
        return token;
    }

    // Could be changed by passing the is... function and applying that
    pub fn readIdentifier(self: *Self) []const u8 {
        const start_pos = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }
        return self.input[start_pos..self.position];
    }

    pub fn readNumber(self: *Self) []const u8 {
        const start_pos = self.position;
        while (isDigit(self.ch)) {
            self.readChar();
        }
        return self.input[start_pos..self.position];
    }

    fn isLetter(character: u8) bool {
        return (character >= 65 and character <= 90) or (character >= 97 and character <= 122) or (character == '_');
    }

    fn isDigit(character: u8) bool {
        return character >= '0' and character <= '9';
    }
};
