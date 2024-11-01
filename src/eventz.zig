const std = @import("std");

pub fn EventSystem(comptime T: type) type {
    return struct {
        const Self = @This();
        const Callback = *const fn (*T) void;

        const Subscriber = struct {
            object: *T,
            callback: Callback,
        };

        allocator: std.mem.Allocator,
        subscribers: std.StringHashMap(std.ArrayList(Subscriber)),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .subscribers = std.StringHashMap(std.ArrayList(Subscriber)).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.subscribers.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.deinit();
            }
            self.subscribers.deinit();
        }

        pub fn registerEvent(self: *Self, event_name: []const u8) !void {
            if (!self.subscribers.contains(event_name)) {
                const list = std.ArrayList(Subscriber).init(self.allocator);
                try self.subscribers.put(event_name, list);
            }
        }

        pub fn subscribe(self: *Self, event_name: []const u8, subscriber: *T, callback: Callback) !void {
            if (self.subscribers.getPtr(event_name)) |subscriber_list| {
                const new_subscriber = Subscriber{
                    .object = subscriber,
                    .callback = callback,
                };
                try subscriber_list.append(new_subscriber);
            } else {
                return error.EventNotRegistered;
            }
        }

        pub fn unsubscribe(self: *Self, event_name: []const u8, subscriber: *T) !void {
            if (self.subscribers.getPtr(event_name)) |subscriber_list| {
                var i: usize = 0;
                while (i < subscriber_list.items.len) {
                    if (subscriber_list.items[i].object == subscriber) {
                        _ = subscriber_list.orderedRemove(i);
                    } else {
                        i += 1;
                    }
                }
            } else {
                return error.EventNotRegistered;
            }
        }

        pub fn trigger(self: *Self, event_name: []const u8) !void {
            if (self.subscribers.get(event_name)) |subscriber_list| {
                for (subscriber_list.items) |subscriber| {
                    subscriber.callback(subscriber.object);
                }
            } else {
                return error.EventNotFound;
            }
        }
    };
}
