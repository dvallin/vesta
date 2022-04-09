import { startOfDay } from "date-fns";
import { MealPlan } from "../../src/model/meal-plan";
import { standardRecipe } from "./recipe";

export const standardMealPlan: MealPlan = {
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
