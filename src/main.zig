const std = @import("std");
const Blockchain = @import("blockchain.zig").Blockchain;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var blockchain = Blockchain.init(allocator);
    defer blockchain.deinit();


    try blockchain.addBlock(100);
    try blockchain.addBlock(200);
    try blockchain.addBlock(300);


    try blockchain.printBlocks();
}
