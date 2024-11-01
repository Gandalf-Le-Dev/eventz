const std = @import("std");
const testing = std.testing;
const EventSystem = @import("eventz").EventSystem;

// Test struct to simulate subscribers
const TestSubscriber = struct {
    value: i32,
    
    fn onEvent(self: *TestSubscriber) void {
        self.value += 1;
    }

    fn onEventDouble(self: *TestSubscriber) void {
        self.value *= 2;
    }
};

test "EventSystem - initialization and deinitialization" {
    const allocator = testing.allocator;
    var event_system = EventSystem(TestSubscriber).init(allocator);
    defer event_system.deinit();

    try testing.expect(event_system.subscribers.count() == 0);
}

test "EventSystem - register event" {
    const allocator = testing.allocator;
    var event_system = EventSystem(TestSubscriber).init(allocator);
    defer event_system.deinit();

    // Register a new event
    try event_system.registerEvent("test_event");
    try testing.expect(event_system.subscribers.contains("test_event"));

    // Register the same event again (should not error)
    try event_system.registerEvent("test_event");
    try testing.expect(event_system.subscribers.count() == 1);
}

test "EventSystem - subscribe to event" {
    const allocator = testing.allocator;
    var event_system = EventSystem(TestSubscriber).init(allocator);
    defer event_system.deinit();

    var subscriber = TestSubscriber{ .value = 0 };

    // Try to subscribe to non-existent event
    try testing.expectError(
        error.EventNotRegistered,
        event_system.subscribe("test_event", &subscriber, TestSubscriber.onEvent)
    );

    // Register and subscribe to event
    try event_system.registerEvent("test_event");
    try event_system.subscribe("test_event", &subscriber, TestSubscriber.onEvent);

    if (event_system.subscribers.get("test_event")) |subscriber_list| {
        try testing.expect(subscriber_list.items.len == 1);
        try testing.expect(subscriber_list.items[0].object == &subscriber);
    } else {
        try testing.expect(false);
    }
}

test "EventSystem - unsubscribe from event" {
    const allocator = testing.allocator;
    var event_system = EventSystem(TestSubscriber).init(allocator);
    defer event_system.deinit();

    var subscriber1 = TestSubscriber{ .value = 0 };
    var subscriber2 = TestSubscriber{ .value = 0 };

    // Try to unsubscribe from non-existent event
    try testing.expectError(
        error.EventNotRegistered,
        event_system.unsubscribe("test_event", &subscriber1)
    );

    // Register and subscribe multiple subscribers
    try event_system.registerEvent("test_event");
    try event_system.subscribe("test_event", &subscriber1, TestSubscriber.onEvent);
    try event_system.subscribe("test_event", &subscriber2, TestSubscriber.onEvent);

    // Verify initial subscription count
    if (event_system.subscribers.get("test_event")) |subscriber_list| {
        try testing.expect(subscriber_list.items.len == 2);
    }

    // Unsubscribe one subscriber
    try event_system.unsubscribe("test_event", &subscriber1);

    // Verify updated subscription count
    if (event_system.subscribers.get("test_event")) |subscriber_list| {
        try testing.expect(subscriber_list.items.len == 1);
        try testing.expect(subscriber_list.items[0].object == &subscriber2);
    }
}

test "EventSystem - trigger event" {
    const allocator = testing.allocator;
    var event_system = EventSystem(TestSubscriber).init(allocator);
    defer event_system.deinit();

    var subscriber1 = TestSubscriber{ .value = 0 };
    var subscriber2 = TestSubscriber{ .value = 5 };

    // Try to trigger non-existent event
    try testing.expectError(
        error.EventNotFound,
        event_system.trigger("test_event")
    );

    // Register and subscribe subscribers with different callbacks
    try event_system.registerEvent("test_event");
    try event_system.subscribe("test_event", &subscriber1, TestSubscriber.onEvent);
    try event_system.subscribe("test_event", &subscriber2, TestSubscriber.onEventDouble);

    // Trigger event and verify callbacks were executed
    try event_system.trigger("test_event");
    try testing.expect(subscriber1.value == 1);
    try testing.expect(subscriber2.value == 10);

    // Trigger again to verify multiple calls work
    try event_system.trigger("test_event");
    try testing.expect(subscriber1.value == 2);
    try testing.expect(subscriber2.value == 20);
}

test "EventSystem - multiple events" {
    const allocator = testing.allocator;
    var event_system = EventSystem(TestSubscriber).init(allocator);
    defer event_system.deinit();

    var subscriber = TestSubscriber{ .value = 0 };

    // Register multiple events
    try event_system.registerEvent("event1");
    try event_system.registerEvent("event2");

    // Subscribe to both events
    try event_system.subscribe("event1", &subscriber, TestSubscriber.onEvent);
    try event_system.subscribe("event2", &subscriber, TestSubscriber.onEventDouble);

    // Trigger events and verify correct callbacks are called
    try event_system.trigger("event1");
    try testing.expect(subscriber.value == 1);

    try event_system.trigger("event2");
    try testing.expect(subscriber.value == 2);
}