const std = @import("std");
pub const Block = @import("block.zig");

pub const BlockChain = std.ArrayList(Block);

pub const Blockchain = struct {
    blocks: BlockChain,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Blockchain {
        return Blockchain{
            .blocks = BlockChain.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn addBlock(self: *Blockchain, block_data: u64) !void {
        const prev_hash = if (self.blocks.items.len > 0) 
            self.blocks.getLast().hash 
        else 
            null;

        const block_index = self.blocks.items.len;
        const new_block = try Block.init(block_data, self.allocator, prev_hash, block_index);

        if (try self.verifyBlock(new_block)) {
            try self.blocks.append(new_block);
        } else {
            var mutable_block = new_block;
            mutable_block.deinit();
            return error.InvalidBlock;
        }
    }

    fn verifyBlock(self: *Blockchain, new_block: Block) !bool {
        // Always verify genesis block
        if (self.blocks.items.len == 0) return true;

        const old_block = self.blocks.getLast();
        if (!std.mem.eql(u8, new_block.prev_hash, old_block.hash)) return false;

        const check_hash = try Block.hashBlock(new_block, self.allocator);
        defer self.allocator.free(check_hash);
        if (!std.mem.eql(u8, new_block.hash, check_hash)) return false;

        if (new_block.index != old_block.index + 1) return false;
        return true;
    }

    pub fn printBlocks(self: *Blockchain) !void {
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();
        for (self.blocks.items) |block| {
            try stdout.print(
                "Block({d}) =>\n\tData -> {d}\n\tCreated at -> {d}\n\tPrev hash -> {s}\n\tHash -> {s}\n\n", 
                .{block.index, block.data, block.created_at, block.prev_hash, block.hash}
            );
        }
        try bw.flush();
    }

    pub fn deinit(self: *Blockchain) void {
        for (self.blocks.items) |*block| {
            block.deinit();
        }
        self.blocks.deinit();
    }
};
