import { useMemo } from "react";
import {
  combineShoppingIngredients,
  ShoppingIngredient,
  ShoppingIngredientFromPlan,
  ShoppingList,
} from "../model/shopping-list";
import { useMealPlan } from "../storage/use-meal-plan";
import { useRecipes } from "../storage/use-recipes";

export default function useShoppingListFromMealPlan(): ShoppingList {
  const { data: plan } = useMealPlan();
  const { data: recipes } = useRecipes();

  return useMemo(() => {
    const shoppingIngredientsByName: Record<string, ShoppingIngredient> = {};

    for (const p of plan?.plans ?? []) {
      const fromPlan: ShoppingIngredientFromPlan = {
        date: p.date,
        recipeId: p.recipeId,
      };

      const recipe = recipes?.find((r) => p.recipeId === r.id);
      for (const i of recipe?.ingredients ?? []) {
        const ingredient = shoppingIngredientsByName[i.ingredientName] || {
          ingredientName: i.ingredientName,
          bought: false,
          fromPlans: [],
        };
        shoppingIngredientsByName[i.ingredientName] =
          combineShoppingIngredients(ingredient, {
            ...i,
            fromPlans: [fromPlan],
            bought: false,
          });
      }
    }

    return {
      shoppingIngredients: Object.values(shoppingIngredientsByName),
    };
  }, [plan, recipes]);
}
