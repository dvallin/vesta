import { parseDuration } from "./duration";

it("parses minutes", () => {
  expect(parseDuration("4m")).toEqual({ minutes: 4 });
});

it("parses hours", () => {
  expect(parseDuration("1h2m")).toEqual({ hours: 1, minutes: 2 });
  expect(parseDuration("3m4h")).toEqual({ hours: 4, minutes: 3 });
});

it("parses days", () => {
  expect(parseDuration("1d")).toEqual({ days: 1 });
  expect(parseDuration("1d2h3m")).toEqual({ days: 1, hours: 2, minutes: 3 });
  expect(parseDuration("3m2h1d")).toEqual({ days: 1, hours: 2, minutes: 3 });
});

it("ignores whitespaces", () => {
  expect(parseDuration("  3m 2d  1h ")).toEqual({
    days: 2,
    hours: 1,
    minutes: 3,
  });
});

it("does not parse strings with unkown characters", () => {
  expect(parseDuration("4d5x6m")).toBeUndefined();
});

it("parses multiple occurrences", () => {
  expect(parseDuration("4d2d")).toEqual({ days: 2 });
});
