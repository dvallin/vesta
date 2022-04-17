import { syncedStore } from "@syncedstore/core";
import { standardMealPlan } from "../../.storybook/data/meal-plan";
import { standardRecipe } from "../../.storybook/data/recipe";
import { standardShoppingList } from "../../.storybook/data/shopping-list";
import { MealPlan } from "../model/meal-plan";
import { ShoppingList } from "../model/shopping-list";
import { State } from "./store";

export default function mockStore() {
  const store = syncedStore<State>({
    mealPlan: {} as MealPlan,
    shoppingList: {} as ShoppingList,
    recipes: [],
  });
  store.mealPlan.plans = standardMealPlan.plans;
  store.shoppingList.shoppingIngredients =
    standardShoppingList.shoppingIngredients;
  store.recipes.push(standardRecipe);
  return store;
}
