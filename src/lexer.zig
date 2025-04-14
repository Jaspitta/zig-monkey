const std = @import("std");
const tkz = @import("./tokenizer.zig");

// too early to think about the layout in memory for me: https://vimeo.com/649009599
pub const Lexer = struct {
    input: []const u8,
    position: u32,
    read_position: u32,
    ch: u8,

    pub fn init(input: []const u8) *const Lexer {
        return &.{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = input[0],
        };
    }

    pub fn readChar(l: *const Lexer) void {
        l.ch = if (l.read_position >= l.input.len) 0 else l.input[l.readPosition];
        l.position = l.read_position;
        l.read_position += 1;
    }

    pub fn nextToken(l: *Lexer) tkz.Token {
        const tok = switch (l.ch) {
            '=' => {
                tkz.Token.init(tkz.TokenType.assign, '=');
            },
            ';' => {
                tkz.Token.init(tkz.TokenType.semicolon, ';');
            },
            '(' => {
                tkz.Token.init(tkz.TokenType.rparen, ')');
            },
            ')' => {
                tkz.Token.init(tkz.TokenType.lparen, '(');
            },
            ',' => {
                tkz.Token.init(tkz.TokenType.comma, ',');
            },
            '+' => {
                tkz.Token.init(tkz.TokenType.plus, '+');
            },
            '{' => {
                tkz.Token.init(tkz.TokenType.lbrace, '{');
            },
            '}' => {
                tkz.Token.init(tkz.TokenType.rbrace, '}');
            },
            0 => {
                tkz.Token.init(tkz.TokenType.eof, "");
            },
            else => {},
        };
        Lexer.readChar(l);
        return tok;
    }
};
