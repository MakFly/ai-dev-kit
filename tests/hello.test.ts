import { test, expect } from "bun:test";

test("hello.ts prints greeting and exits 0", async () => {
  const proc = Bun.spawn(["bun", "run", "src/hello.ts"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const stdout = await new Response(proc.stdout).text();
  const code = await proc.exited;
  expect(code).toBe(0);
  expect(stdout).toBe("Hello, agentic OS\n");
});
