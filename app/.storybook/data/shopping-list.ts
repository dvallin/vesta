import { Entity } from "../../src/model/entity";
import { ShoppingList } from "../../src/model/shopping-list";
import { SwrCache, createCache } from "./swr-cache";

export const standardShoppingList: Entity<ShoppingList> = {
  id: "1",
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

export const shoppingLists: () => SwrCache = () =>
  createCache(["shopping-list", standardShoppingList]);
