const std = @import("std");
const net = std.net;
const print = std.debug.print;

pub fn connect(allocator: std.mem.Allocator) !void {
    const loopback = try net.Ip4Address.parse("127.0.0.1", 6969);
    const localhost = net.Address{ .in = loopback };
    var server = try localhost.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = 4,
    });
    defer pool.deinit();

    //TODO: Handle these errors better
    const addr = server.listen_address;
    print("Listening on {}, access this port to end the program\n", .{addr.getPort()});

    while(true) {
        var client = try server.accept();
        try pool.spawn(handleConn, .{&client, allocator});
    }

}

//TODO: Handle these errors better
fn handleConn(client: *net.Server.Connection, allocator: std.mem.Allocator) void {
    defer client.stream.close();
    print("Connection received! {} is sending data.\n", .{client.address});
    const message = client.stream.reader().readAllAlloc(allocator, 1024) catch undefined;
    defer allocator.free(message);
    print("{} says {s}\n", .{ client.address, message });
}
