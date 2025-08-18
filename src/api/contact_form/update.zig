const std = @import("std");
const pg = @import("pg");
const Success = @import("../../response.zig").Success;
const ContactForm = @import("../../model.zig").ContactForm;

const UpdateDTO = struct {
    value: bool,
};

pub fn updateConfirm(
    pool: *pg.Pool,
    id: i32,
    dto: UpdateDTO,
) !Success(?u8) {
    try ContactForm.updateConfirm(
        pool,
        id,
        dto.value,
    );
    return .{
        .message = "Update contact form confirmation successfully!",
        .data = null,
    };
}
