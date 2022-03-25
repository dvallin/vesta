import { z } from "zod";

export const durationSchema = z.object({
  years: z.number().optional(),
  months: z.number().optional(),
  weeks: z.number().optional(),
  days: z.number().optional(),
  hours: z.number().optional(),
  minutes: z.number().optional(),
  seconds: z.number().optional(),
});
export type Duration = typeof durationSchema._type;

const partLookup: Record<string, keyof Duration> = {
  // eslint-disable-next-line @typescript-eslint/naming-convention
  Y: "years",
  // eslint-disable-next-line @typescript-eslint/naming-convention
  M: "months",
  w: "weeks",
  d: "days",
  h: "hours",
  m: "minutes",
  s: "seconds",
};

export function parseDuration(value: string): Duration | undefined {
  const duration: Duration = {};

  const partRegex = /^(\d+)([MYdhmsw|])/;

  let remaining = value.replaceAll(" ", "");
  while (remaining.length > 0) {
    const match = partRegex.exec(remaining);
    if (!match) {
      return undefined;
    }

    remaining = remaining.slice(match[0].length);
    duration[partLookup[match[2]]] = Number.parseInt(match[1], 10);
  }

  return duration;
}

const format = (v: number | undefined, p: string) => (v ? `${v}${p}` : "");
export function formatDuration(duration: Duration): string {
  return ["Y", "M", "w", "d", "h", "m", "s"]
    .map((k) => format(duration[partLookup[k]], k))
    .filter((v) => v)
    .join(" ");
}
