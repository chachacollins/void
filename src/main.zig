const std = @import("std");
const Blockchain = @import("blockchain.zig").Blockchain;
const net = @import("net.zig");
const AsyncQueue = @import("asyncqueue.zig").AsyncQueue;

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
    var queue = AsyncQueue(usize).init(allocator);
    try queue.enqueue(10);
    std.debug.print("{d}\n", .{queue.dequeue().?});
}
