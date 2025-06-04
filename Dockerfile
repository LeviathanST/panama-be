FROM leviathanst/zig:latest AS build

WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseSafe

FROM alpine AS final
COPY --from=build /app/zig-out/bin/panama_be /exe
CMD ["/exe"]
