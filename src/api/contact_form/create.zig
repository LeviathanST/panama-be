const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const ContactForm = @import("../../model.zig").ContactForm;

const InsertDTO = struct {
    name: []const u8,
    email: []const u8,
    interest_area: []const u8,
    content: []const u8,
};

pub fn create(
    pool: *pg.Pool,
    dto: InsertDTO,
) !Success(?u8) {
    try ContactForm.insert(
        pool,
        dto.name,
        dto.email,
        dto.interest_area,
        dto.content,
    );
    return .{
        .message = "Add a contact form successfully!",
        .data = null,
    };
}
