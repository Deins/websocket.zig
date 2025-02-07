const std = @import("std");
const builtin = @import("builtin");
const t = @import("t.zig");

const mem = std.mem;
const Stream = if (builtin.is_test) *t.Stream else std.net.Stream;

const RequestError = error{
	Invalid,
	TooLarge,
};

pub const Request = struct {
	pub fn read(stream: Stream, buf: []u8) ![]u8 {
		@setRuntimeSafety(builtin.is_test);

		var total: usize = 0;
		while (true) {
			if (total == buf.len) {
				return RequestError.TooLarge;
			}

			var n = try stream.read(buf[total..]);
			if (n == 0) {
				return RequestError.Invalid;
			}
			total += n;
			const request = buf[0..total];
			if (mem.endsWith(u8, request, "\r\n\r\n")) {
				return request;
			}
		}
	}

	pub fn close(stream: Stream, err: anyerror) !void {
		try stream.writeAll("HTTP/1.1 400 Invalid\r\nerror: ");
		const s = switch (err) {
			error.Invalid => "invalid",
			error.TooLarge => "toolarge",
			else => "unknown",
		};
		try stream.writeAll(s);
		try stream.writeAll("\r\n\r\n");
	}
};
