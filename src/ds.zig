const std = @import("std");

pub fn AsyncQueue(comptime T: type) type {
    return struct {
        const Node = struct {
            data: T,
            next: ?*Node = null,
        };
        const Self = @This();
        allocator: std.mem.Allocator,
        len: usize,
        head: ?*Node,
        tail: ?*Node,
        mutex: std.Thread.Mutex,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = allocator,
                .mutex = std.Thread.Mutex{},
            };
        }

        pub fn enqueue(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.data = value;
            self.mutex.lock();
            defer self.mutex.unlock();
            if (self.tail) |tail| {
                tail.next = node;
                self.tail = node;
            } else {
                self.tail = node;
                self.head = node;
            }
            self.len += 1;
        }

        pub fn dequeue(self: *Self) ?T {
            self.mutex.lock();
            defer self.mutex.unlock();
            const head = self.head orelse return null;
            self.len -= 1;
            self.head = head.next;
            if (self.head == null) {
                self.tail = null;
            }
            const value = head.data;
            self.allocator.destroy(head);
            return value;
        }

        pub fn isEmpty(self: *Self) bool {
            self.mutex.lock();
            defer self.mutex.unlock();
            return self.head == null;
        }
    };
}

pub fn AsyncArrayList(comptime T: type) type {
    return struct {
        const Self = @This();
        backing: std.ArrayList(T),
        mutex: std.Thread.Mutex,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .backing = std.ArrayList(T).init(allocator),
                .mutex = std.Thread.Mutex{}
            };
        }

        pub fn deinit(self: *Self) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.backing.deinit();
        }

        pub fn append(self:*Self, item: T) !void {
            self.mutex.lock();
            defer self.mutex.unlock();
            try self.backing.append(item);
        } 

        pub fn get(self:*Self, index: usize) T {
            self.mutex.lock();
            defer self.mutex.unlock();
            return self.backing.items[index];
        }

        pub fn set(self:*Self, index: usize, item: T) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.backing.items[index] = item;
        }
        pub fn len(self: Self) usize {
            return self.backing.items.len;
        }
    };
}
