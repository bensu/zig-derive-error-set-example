const std = @import("std");

// We want to hide this from the user
const InternalError = error{Internal};

// We want to expose this to the user
pub const PublicError = error{Public};

fn internal_function() !u32 {
    if (true) {
        return error.Internal;
    } else {
        return error.PublicError;
    }
    return 1;
}

// Handles the Internal error but exposes the Public error
fn public_api() PublicError!u32 {
    if (internal_function()) |result| {
        return result;
    } else |err| switch (err) {
        error.Internal => return 0,
        // err can no longer be error.Internal
        else => return err,
    }
}

pub fn main() !void {
    const a = public_api();
    try std.debug.assert(a == 0);
}

test "simple test" {
    const a = public_api();
    try std.testing.expectEqual(a, 0);
}

// We get this error when running zig test:

// $ zig test src/main.zig
//
// src/main.zig:24:24: error: expected type 'error{Public}', found '@typeInfo(@typeInfo(@TypeOf(main.internal_function)).Fn.return_type.?).ErrorUnion.error_set'
//         else => return err,
//                        ^~~
// src/main.zig:24:24: note: 'error.Internal' not a member of destination error set
// referenced by:
//     test.simple test: src/main.zig:34:15
//     remaining reference traces hidden; use '-freference-trace' to see all reference traces

// I would've expected the compiler to figure out that `err` can no longer be `error.Internal` and remove that from the derived error set.
