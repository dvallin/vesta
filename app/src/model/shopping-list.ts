import { z } from "zod";
import { uniqueArray } from "../unique";

export const shoppingIngredientFromPlanSchema = z.object({
  date: z.number(),
  recipeId: z.string(),
});

export const shoppingIngredientSchema = z.object({
  amount: z.number().optional(),
  unit: z.string().optional(),
  ingredientName: z.string(),
  bought: z.boolean(),
  fromPlans: z.array(shoppingIngredientFromPlanSchema),
});

export const shoppingListSchema = z.object({
  shoppingIngredients: z.array(shoppingIngredientSchema),
});

export type ShoppingList = typeof shoppingListSchema._type;
export type ShoppingIngredient = typeof shoppingIngredientSchema._type;
export type ShoppingIngredientFromPlan =
  typeof shoppingIngredientFromPlanSchema._type;

export function combine(left: ShoppingList, right: ShoppingList): ShoppingList {
  const combinedIngredientsByName: Record<string, ShoppingIngredient> = {};
  const combinedIngredients = [
    ...left.shoppingIngredients,
    ...right.shoppingIngredients,
  ];
  for (const ingredient of combinedIngredients) {
    combinedIngredientsByName[ingredient.ingredientName] =
      combineShoppingIngredients(
        ingredient,
        combinedIngredientsByName[ingredient.ingredientName] || {
          fromPlans: [],
        }
      );
  }

  return {
    shoppingIngredients: Object.values(combinedIngredientsByName),
  };
}

export function combineShoppingIngredients(
  left: ShoppingIngredient,
  right: ShoppingIngredient
): ShoppingIngredient {
  const fromPlans = uniqueArray(
    [...left.fromPlans, ...right.fromPlans],
    (plan) => `${plan.date}-${plan.recipeId}`
  );
  return {
    ingredientName: left.ingredientName,
    unit: left.unit,
    bought: left.bought,
    amount:
      left.amount || right.amount
        ? (left.amount ?? 0) + (right.amount ?? 0)
        : undefined,
    fromPlans,
  };
}

export function sortByName(a: ShoppingIngredient, b: ShoppingIngredient) {
  return a.ingredientName.localeCompare(b.ingredientName);
}
