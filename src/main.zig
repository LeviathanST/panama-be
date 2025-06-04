const std = @import("std");
const tk = @import("tokamak");
const App = @import("App.zig");
const Config = @import("Config.zig");

pub fn main() !void {
    try tk.app.run(&.{App});
}
