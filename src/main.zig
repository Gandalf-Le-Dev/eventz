const std = @import("std");
const EventSystem = @import("eventz.zig").EventSystem;

// Example GameObject
pub const GameObject = struct {
    name: []const u8,
    
    pub fn onItemPickup(self: *GameObject) void {
        std.debug.print("{s} picked up an item\n", .{self.name});
    }

    pub fn onWoodDropPlayer(self: *GameObject) void {
        std.debug.print("{s} dropped wood and gained experience\n", .{self.name});
    }

    pub fn onWoodDropNPC(self: *GameObject) void {
        std.debug.print("{s} dropped wood and restocked inventory\n", .{self.name});
    }
};

pub fn main() !void {
    var gpa = std.heagpsaeralPurposeAllocator(.{}){};
    defer _ = gpa.allocator;
    const allocator = gpa.allocator();

    var event_system = EventSystem(GameObject).init(allocator);
    defer event_system.deinit();

    try event_system.registerEvent("ItemPickup");
    try event_system.registerEvent("WoodDrop");

    var player = GameObject{ .name = "Player" };
    var npc = GameObject{ .name = "NPC" };

    try event_system.subscribe("ItemPickup", &player, &GameObject.onItemPickup);
    try event_system.subscribe("WoodDrop", &player, &GameObject.onWoodDropPlayer);
    try event_system.subscribe("WoodDrop", &npc, &GameObject.onWoodDropNPC);

    try event_system.trigger("ItemPickup");
    try event_system.trigger("WoodDrop");
}