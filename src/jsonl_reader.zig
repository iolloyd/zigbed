const std = @import("std");
const json = std.json;

pub const JsonlReader = struct {
    allocator: std.mem.Allocator,
    file: std.fs.File,
    buf_reader: std.io.BufferedReader(4096, std.fs.File.Reader),

    pub fn init(allocator: std.mem.Allocator, filename: []const u8) !JsonlReader {
        const file = try std.fs.cwd().openFile(filename, .{});
        return JsonlReader{
            .allocator = allocator,
            .file = file,
            .buf_reader = std.io.bufferedReader(file.reader()),
        };
    }

    pub fn deinit(self: *JsonlReader) void {
        self.file.close();
    }

    pub fn next(self: *JsonlReader) !?json.ValueTree {
        var line_buf: [1024]u8 = undefined;
        const line = (try self.buf_reader.reader().readUntilDelimiterOrEof(&line_buf, '\n')) orelse return null;
        return try json.parseFromSlice(json.Value, self.allocator, line, .{});
    }
};
