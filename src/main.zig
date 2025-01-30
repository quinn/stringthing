const std = @import("std");

pub fn main() !void {
    // Read flag 'd' from command-line arguments
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <delimiter>\n", .{args[0]});
        return;
    }
    const delimiter = args[1];

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    while (true) {
        const line = stdin.readUntilDelimiterOrEofAlloc(allocator, delimiter[0], 1024) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        } orelse break;
        defer allocator.free(line);

        stdout.print("{s}\n", .{line}) catch |err| {
            if (err == error.BrokenPipe) return;
            return err;
        };
    }

    bw.flush() catch |err| {
        if (err == error.BrokenPipe) return;
        return err;
    };
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
