import { startOfDay } from "date-fns";
import { Entity } from "../../src/model/entity";
import { MealPlan } from "../../src/model/meal-plan";
import { standardRecipe } from "./recipe";
import { SwrCache, createCache } from "./swr-cache";

export const standardMealPlan: Entity<MealPlan> = {
  id: "1",
  plans: [
    {
      date: startOfDay(new Date()).getTime(),
      recipeId: standardRecipe.id,
    },
    {
      date: startOfDay(new Date()).getTime(),
      recipeId: standardRecipe.id,
    },
    {
      date: startOfDay(new Date()).getTime(),
      recipeId: standardRecipe.id,
    },
    {
      date: startOfDay(new Date()).getTime(),
      recipeId: standardRecipe.id,
    },
  ],
};

export const mealPlans: () => SwrCache = () =>
  createCache(["meal-plan", standardMealPlan]);
