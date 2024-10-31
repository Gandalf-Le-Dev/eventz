const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the module
    const eventz_mod = b.addModule("eventz", .{
        .root_source_file = b.path("src/eventz.zig"),
        .imports = &.{},
    });

    // Create executable for integration tests
    const exe = b.addExecutable(.{
        .name = "eventz-test",  // Changed name to clarify it's for testing
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("eventz", eventz_mod);
    
    // Add run step for integration tests
    const run = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run integration tests");  // Updated description
    run_step.dependOn(&run.step);

    // Unit tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/eventz.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}