const tk = @import("tokamak");
const App = @import("App.zig");

pub fn main() !void {
    try tk.app.run(tk.Server.start, &.{App});
}
