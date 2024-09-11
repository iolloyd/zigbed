const std = @import("std");
const JsonlReader = @import("jsonl_reader.zig").JsonlReader;
const EmbeddingGenerator = @import("embedding_generator.zig").EmbeddingGenerator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var reader = try JsonlReader.init(allocator, "data.jsonl");
    defer reader.deinit();

    var generator = try EmbeddingGenerator.init(allocator, "path/to/your/model.onnx");
    defer generator.deinit();

    while (try reader.next()) |json| {
        const text = json.get("text") orelse continue;
        const embedding = try generator.generateEmbedding(text);
        // Do something with the embedding, e.g., write to a file
    }
}
