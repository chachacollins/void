const std = @import("std");
const hasher = std.crypto.hash.sha2.Sha256;

const Block = struct {
    prev_hash: []const u8,
    hash: []const u8,
    data: u64,
    created_at: i64,
    allocator: std.mem.Allocator,
    index: usize,

    pub fn init(data: u64, allocator: std.mem.Allocator) !Block {
        var block = Block{
            .created_at = std.time.milliTimestamp(),
            .data = data,
            .hash = "",
            .prev_hash = "",
            .allocator = allocator,
            .index = block_chain.items.len,
        };
        if (block_chain.items.len > 0) {
            const prev_block = block_chain.getLast();
            block.prev_hash = try allocator.dupe(u8, prev_block.hash);
        } else {
            block.prev_hash = try allocator.dupe(u8, "");
        }
        block.hash = try hashBlock(block, allocator);
        return block;
    }

    pub fn deinit(self: *Block) void {
        self.allocator.free(self.prev_hash);
        self.allocator.free(self.hash);
    }
};

const BlockChain = std.ArrayList(Block);
var block_chain: BlockChain = undefined;

fn hashBlock(block: Block, allocator: std.mem.Allocator) ![]const u8 {
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

fn verifyBlock(new_block: Block, allocator: std.mem.Allocator) !bool {
    // Always verify genesis block
    if (block_chain.items.len == 0) return true;
    const old_block = block_chain.getLast();
    if (!std.mem.eql(u8, new_block.prev_hash, old_block.hash)) return false;
    const check_hash = try hashBlock(new_block, allocator);
    defer allocator.free(check_hash);
    if (!std.mem.eql(u8, new_block.hash, check_hash)) return false;
    if (new_block.index != old_block.index + 1) return false;
    return true;
}

fn addBlock(block: Block, allocator: std.mem.Allocator) !bool {
    if (!try verifyBlock(block, allocator)) return false;
    try block_chain.append(block);
    return true;
}

fn printBlocks() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    for (block_chain.items) |block| {
        try stdout.print(
            "Block({d}) =>\n\tData -> {d}\n\tCreated at -> {d}\n\tPrev hash -> {s}\n\tHash -> {s}\n\n", 
            .{block.index, block.data, block.created_at, block.prev_hash, block.hash}
        );
    }
    try bw.flush();
}

fn cleanUp() void {
    for (block_chain.items) |*block| {
        block.deinit();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    block_chain = BlockChain.init(allocator);
    defer block_chain.deinit();
    defer cleanUp();
    const genesis_block = try Block.init(69420, allocator);
    if (!try addBlock(genesis_block, allocator)) {
        return error.CouldNotAddGenesisBlock;
    }
    const block2 = try Block.init(67890, allocator);
    if (!try addBlock(block2, allocator)) {
        return error.CouldNotAddGenesisBlock;
    }
    try printBlocks();
}
