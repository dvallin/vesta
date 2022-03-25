import {
  combine,
  combineShoppingIngredients,
  ShoppingIngredient,
} from "./shopping-list";

const ingredient = (
  ingredientName: string,
  amount: number
): ShoppingIngredient => ({
  ingredientName,
  bought: false,
  amount,
  fromPlans: [],
});

describe("combine", () => {
  it("combines ingredients by name", () => {
    expect(
      combine(
        { shoppingIngredients: [ingredient("a", 1), ingredient("b", 1)] },
        { shoppingIngredients: [ingredient("b", 1), ingredient("c", 1)] }
      )
    ).toEqual({
      shoppingIngredients: [
        ingredient("a", 1),
        ingredient("b", 2),
        ingredient("c", 1),
      ],
    });
  });
});

describe("combineShoppingIngredients", () => {
  it("just takes left values", () => {
    const combined = combineShoppingIngredients(
      { ingredientName: "left", unit: "left", bought: true, fromPlans: [] },
      { ingredientName: "right", unit: "right", bought: false, fromPlans: [] }
    );
    expect(combined).toEqual({
      ingredientName: "left",
      unit: "left",
      bought: true,
      fromPlans: [],
    });
  });
  it("adds amounts", () => {
    const combined = combineShoppingIngredients(
      { ingredientName: "left", amount: 2, bought: true, fromPlans: [] },
      { ingredientName: "right", amount: 0.5, bought: false, fromPlans: [] }
    );
    expect(combined).toEqual({
      ingredientName: "left",
      amount: 2.5,
      bought: true,
      fromPlans: [],
    });
  });
  it("defaults amounts", () => {
    const combined = combineShoppingIngredients(
      { ingredientName: "left", amount: 2, bought: true, fromPlans: [] },
      {
        ingredientName: "right",
        amount: undefined,
        bought: false,
        fromPlans: [],
      }
    );
    expect(combined).toEqual({
      ingredientName: "left",
      amount: 2,
      bought: true,
      fromPlans: [],
    });
  });
  it("combines unique plans", () => {
    const combined = combineShoppingIngredients(
      {
        ingredientName: "left",
        bought: true,
        fromPlans: [
          { date: 1, recipeId: "recipe1" },
          { date: 2, recipeId: "recipe1" },
          { date: 1, recipeId: "recipe2" },
        ],
      },
      {
        ingredientName: "right",
        bought: false,
        fromPlans: [
          { date: 1, recipeId: "recipe1" },
          { date: 2, recipeId: "recipe1" },
          { date: 2, recipeId: "recipe2" },
        ],
      }
    );
    expect(combined).toEqual({
      ingredientName: "left",
      bought: true,
      fromPlans: [
        { date: 1, recipeId: "recipe1" },
        { date: 2, recipeId: "recipe1" },
        { date: 1, recipeId: "recipe2" },
        { date: 2, recipeId: "recipe2" },
      ],
    });
  });
});
