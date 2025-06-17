const tk = @import("tokamak");
const App = @import("App.zig");

pub fn main() !void {
    try tk.app.run(&.{App});
}
