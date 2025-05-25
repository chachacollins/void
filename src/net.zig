const std = @import("std");
const Blockchain = @import("blockchain.zig").Blockchain;
const Block = @import("blockchain.zig").Block;
//TODO: remove this and use it to backupt the blockchain array instead
const AsyncArrayList = @import("ds.zig").AsyncArrayList;
const net = std.net;
const print = std.debug.print;

const Config = struct {
    allocator: std.mem.Allocator,
    threads: u3,
    block_chain: *Blockchain,
};

var blocks: AsyncArrayList(Block) = undefined;

pub fn connect(config: Config) !void {
    const loopback = try net.Ip4Address.parse("127.0.0.1", 6969);
    const localhost = net.Address{ .in = loopback };
    var server = try localhost.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{
        .allocator = config.allocator,
        .n_jobs = config.threads,
    });
    defer pool.deinit();

    blocks = AsyncArrayList(Block).init(config.allocator);
    //TODO: Handle these errors better
    const addr = server.listen_address;
    print("Listening on {}\n", .{addr.getPort()});

    while (true) {
        var client = try server.accept();
        try pool.spawn(handleConn, .{ &client, config.block_chain });
    }
}

//TODO: Handle these errors better
fn handleConn(client: *net.Server.Connection, block_chain: *Blockchain) void {
    defer client.stream.close();
    print("Connection received! {} is sending data.\n", .{client.address});
    client.stream.writeAll(">> ") catch undefined;
    var buffer: [1024]u8 = undefined;
    _ = client.stream.reader().read(&buffer) catch undefined;
    const int  = std.fmt.parseInt(u64, &buffer, 10) catch undefined;
    block_chain.addBlock(int) catch undefined;
    print("{} added {s}: block id {d}\n", .{ client.address, buffer, block_chain.blocks.getLast().index });
    var msg: [1024]u8 = undefined;
    for(block_chain.blocks.items) |block| {
        const message =  std.fmt.bufPrint(&msg, 
                            "Block({d}) =>\n\tData -> {d}\n\tCreated at -> {d}\n\tPrev hash -> {s}\n\tHash -> {s}\n\n", 
                            .{block.index, block.data, block.created_at, block.prev_hash, block.hash}
                        ) catch undefined;
        client.stream.writeAll(message) catch undefined;
    }
}
