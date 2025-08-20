const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const ContactForm = @import("../../model.zig").ContactForm;

pub fn delete(
    pool: *pg.Pool,
    id: i32,
) !Success(?u8) {
    try ContactForm.delete(pool, id);
    return .{
        .message = "Delete a contact form successfully!",
        .data = null,
    };
}
