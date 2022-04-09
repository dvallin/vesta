import { renderHookWithDecorators } from "../decorators";
import mockStore from "../storage/mock-store";
import { standardMealPlan } from "../../.storybook/data/meal-plan";
import useAddMealPlanForm from "./use-add-meal-plan-form";

jest.mock("../storage/store", () => ({ store: mockStore() }));

const render = () =>
  renderHookWithDecorators(useAddMealPlanForm, undefined, []);

it("initializes state", () => {
  const { result } = render();
  expect(result.current.getValues()).toEqual({
    shoppingIngredients: [
      {
        amount: 4,
        bought: false,
        fromPlans: [standardMealPlan.plans[0]],
        ingredientName: "potato",
        unit: undefined,
      },
      {
        amount: 49.2,
        bought: false,
        fromPlans: [standardMealPlan.plans[0]],
        ingredientName: "mayonnaise",
        unit: undefined,
      },
      {
        amount: 40,
        bought: false,
        fromPlans: [standardMealPlan.plans[0]],
        ingredientName: "tomatoes",
        unit: undefined,
      },
      {
        amount: undefined,
        bought: false,
        fromPlans: [standardMealPlan.plans[0]],
        ingredientName: "salt",
        unit: undefined,
      },
    ],
  });
});
