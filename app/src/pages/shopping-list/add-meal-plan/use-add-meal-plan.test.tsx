import { renderHookWithDecorators } from "../../../decorators";
import mockStore from "../../../storage/mock-store";
import { standardMealPlan } from "../../../../.storybook/data/meal-plan";
import useAddMealPlan from "./use-add-meal-plan";

jest.mock("../../../storage/store", () => ({ store: mockStore() }));

const render = () => renderHookWithDecorators(useAddMealPlan, undefined, []);

it("initializes state", () => {
  const { result } = render();
  expect(result.current.methods.getValues()).toEqual({
    shoppingIngredients: [
      {
        amount: 4,
        bought: false,
        fromPlans: [standardMealPlan.plans[0]],
        ingredientName: "potato",
        unit: "kg",
      },
      {
        amount: 49.2,
        bought: false,
        fromPlans: [standardMealPlan.plans[0]],
        ingredientName: "mayonnaise",
        unit: "g",
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
