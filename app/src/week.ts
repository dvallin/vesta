import { add, startOfWeek, endOfWeek, startOfToday } from "date-fns";
import { de } from "date-fns/locale";

export type DayItem = { type: "day"; date: number };
export function dayList(current: Date = new Date()): DayItem[] {
  let date = startOfWeek(current, { locale: de });
  const end = endOfWeek(current, { locale: de });

  const result: DayItem[] = [];
  while (date < end) {
    if (date >= startOfToday()) {
      result.push({ type: "day", date: date.getTime() });
    }

    date = add(date, { days: 1 });
  }

  return result;
}

export type WeekItem = { type: "week"; date: number };
export function getWeekList(
  current: Date = new Date(),
  weeks = 2
): Array<DayItem | WeekItem> {
  const result: Array<DayItem | WeekItem> = [];
  let date = startOfWeek(current, { locale: de });
  for (let week = 0; week < weeks; week++) {
    result.push({ type: "week", date: date.getTime() }, ...dayList(date));
    date = add(date, { weeks: 1 });
  }

  return result;
}
