const std = @import("std");
const tkz = @import("./tokenizer.zig");

// too early to think about the layout in memory for me: https://vimeo.com/649009599
const Lexer = struct {
    input: []u8,
    position: u32,
    read_position: u32,
    ch: u8,

    fn readChar(l: *Lexer) void {
        l.ch = if (l.read_position >= l.input.len) 0 else l.input[l.readPosition];
        l.position = l.read_position;
        l.read_position += 1;
    }

    fn nextToken(l: *Lexer) tkz.Token {
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
