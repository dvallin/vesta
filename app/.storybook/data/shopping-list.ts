import { ShoppingList } from "../../src/model/shopping-list";

export const standardShoppingList: ShoppingList = {
  shoppingIngredients: [
    {
      ingredientName: "potato",
      amount: 1,
      unit: "kg",
      bought: false,
      fromPlans: [],
    },
    {
      ingredientName: "mayonnaise",
      amount: 12.3,
      unit: "g",
      bought: false,
      fromPlans: [],
    },
    { ingredientName: "tomatoes", amount: 10, bought: false, fromPlans: [] },
    { ingredientName: "salt", bought: false, fromPlans: [] },
  ],
};
