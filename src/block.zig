const std = @import("std");
const Block = @This();

prev_hash: []const u8,
hash: []const u8,
data: u64,
created_at: i64,
allocator: std.mem.Allocator,
index: usize,

pub fn init(data: u64, allocator: std.mem.Allocator, prev_block_hash: ?[]const u8, block_index: usize) !Block {
    var block = Block{
        .created_at = std.time.milliTimestamp(),
        .data = data,
        .hash = "",
        .prev_hash = "",
        .allocator = allocator,
        .index = block_index,
    };

    if (prev_block_hash) |prev_hash| {
        block.prev_hash = try allocator.dupe(u8, prev_hash);
    } else {
        block.prev_hash = try allocator.dupe(u8, "");
    }

    block.hash = try hashBlock(block, allocator);
    return block;
}

pub fn hashBlock(block: Block, allocator: std.mem.Allocator) ![]const u8 {
    const hasher = std.crypto.hash.sha2.Sha256;
    var digest_buf: [hasher.digest_length]u8 = undefined;
    var buf: [1024]u8 = undefined;
    const buffer = try std.fmt.bufPrint(
        &buf, 
        "{d}{d}{d}{s}", 
        .{block.index, block.data, block.created_at, block.prev_hash}
    );
    hasher.hash(buffer, &digest_buf, .{});
    var hex_buf: [hasher.digest_length * 2]u8 = undefined;
    _ = try std.fmt.bufPrint(&hex_buf, "{s}", .{std.fmt.fmtSliceHexLower(&digest_buf)});
    return try allocator.dupe(u8, &hex_buf);
}

pub fn deinit(self: *Block) void {
    self.allocator.free(self.prev_hash);
    self.allocator.free(self.hash);
}
