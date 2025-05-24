const std = @import("std");
const Blockchain = @import("blockchain.zig").Blockchain;
const net = @import("net.zig");
const AsyncQueue = @import("ds.zig").AsyncQueue;
const AsyncArrayList = @import("ds.zig").AsyncArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // var blockchain = Blockchain.init(allocator);
    // defer blockchain.deinit();
    //
    // try blockchain.addBlock(100);
    // try blockchain.addBlock(200);
    // try blockchain.addBlock(300);
    //
    // try blockchain.printBlocks();
    // try net.connect(allocator);
    var async_list = AsyncArrayList(u8).init(allocator);
    defer async_list.deinit();
    try async_list.append(10);
    try async_list.append(10);
    try async_list.append(10);
    for(0..async_list.len()) |i| {
        std.debug.print("{d}\n", .{async_list.get(i)});
    }
}
