import { act } from "@testing-library/react-hooks";
import { startOfTomorrow, startOfToday } from "date-fns";
import {
  formDecorator,
  renderHookWithDecorators,
  swrDecorator,
} from "../decorators";
import { MealItem } from "../model/meal-plan";
import useMealPlanFields from "./use-meal-plan-fields";

jest.useFakeTimers().setSystemTime(new Date("2020-01-01").getTime());

const render = () =>
  renderHookWithDecorators(useMealPlanFields, undefined, [
    formDecorator(),
    swrDecorator(),
  ]);

const filterMeals = (
  result: ReturnType<typeof useMealPlanFields>
): MealItem[] =>
  result.items.filter(({ type }) => type === "meal") as MealItem[];

it("initializes", () => {
  const { result } = render();
  expect(result.current.items).toHaveLength(14);
});

it("adds fields to today", () => {
  const { result } = render();
  act(() => {
    result.current.add();
  });
  expect(result.current.items).toHaveLength(15);
  expect(filterMeals(result.current)).toHaveLength(1);
});

it("removes fields", () => {
  const { result } = render();
  act(() => {
    result.current.add();
    result.current.remove(0);
  });
  expect(filterMeals(result.current)).toHaveLength(0);
  expect(result.current.items).toHaveLength(14);
});

it("moves fields", () => {
  const { result } = render();
  act(() => {
    result.current.add();
    result.current.add();
  });
  expect(filterMeals(result.current).map(({ date }) => date)).toEqual([
    startOfToday().getTime(),
    startOfToday().getTime(),
  ]);

  const from = result.current.items.findIndex(
    ({ date, type }) => type === "meal" && date === startOfToday().getTime()
  );
  const complete = jest.fn();
  act(() => {
    result.current.reorder({ from, to: 4, complete });
  });

  expect(complete).toHaveBeenCalled();

  expect(filterMeals(result.current).map(({ date }) => date)).toEqual([
    startOfToday().getTime(),
    startOfTomorrow().getTime(),
  ]);
});
