FROM leviathanst/zig:0.14.1 AS build

WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseSafe

FROM alpine AS final
COPY --from=build /app/zig-out/bin/panama_be /exe
CMD ["/exe"]
