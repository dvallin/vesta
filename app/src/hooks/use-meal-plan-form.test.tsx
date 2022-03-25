import { standardMealPlan } from "../../.storybook/data/meal-plan";
import { renderHookWithDecorators } from "../decorators";
import { MealPlan } from "../model/meal-plan";
import useMealPlanForm from "./use-meal-plan-form";

const render = (plan?: MealPlan) =>
  renderHookWithDecorators(useMealPlanForm, plan, []);

it("initializes state", () => {
  const { result } = render(standardMealPlan);
  expect(result.current.getValues()).toEqual(standardMealPlan);
});

it("resets state", () => {
  const { result, rerender } = render();
  rerender(standardMealPlan);
  expect(result.current.getValues()).toEqual(standardMealPlan);
});
