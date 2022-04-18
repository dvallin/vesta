import { z } from "zod";
import { uniqueArray } from "../array/unique";

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

export function addIngredient(
  shoppingList: Partial<ShoppingList>,
  ingredient: ShoppingIngredient
): void {
  // we can only add it to the same ingredient and unit (no unit conversion yet)
  const current = shoppingList.shoppingIngredients?.find(
    (i) =>
      i.ingredientName === ingredient.ingredientName &&
      i.unit === ingredient.unit
  );
  if (!current) {
    shoppingList.shoppingIngredients?.push(ingredient);
  } else {
    // add amounts
    if (ingredient.amount !== undefined && current.amount !== undefined) {
      current.amount += ingredient.amount;
    }
    // merge plan references
    for (const plan of ingredient.fromPlans) {
      const hasPlan = current.fromPlans.find(
        (p) => p.date === plan.date && p.recipeId === plan.recipeId
      );
      if (!hasPlan) {
        current.fromPlans.push(plan);
      }
    }
  }
}
