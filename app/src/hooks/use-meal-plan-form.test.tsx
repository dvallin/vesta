import { standardMealPlan } from "../../.storybook/data/meal-plan";
import { renderHookWithDecorators } from "../decorators";
import mockStore from "../storage/mock-store";
import useMealPlanForm from "./use-meal-plan-form";

jest.mock("../storage/store", () => ({ store: mockStore() }));

const render = () => renderHookWithDecorators(useMealPlanForm, undefined, []);

it("initializes state", () => {
  const { result } = render();
  expect(result.current.getValues()).toEqual(standardMealPlan);
});
