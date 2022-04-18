import { z } from "zod";
import { uniqueArray } from "../array/unique";
import { Entity } from "./entity";
import { MealPlan } from "./meal-plan";
import { Recipe } from "./recipe";

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

export function createShoppingListFromMealPlan(
  plan: Partial<MealPlan> | undefined,
  recipes: Entity<Recipe>[] | undefined
): ShoppingList {
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
      shoppingIngredientsByName[i.ingredientName] = combineShoppingIngredients(
        ingredient,
        {
          ...i,
          fromPlans: [fromPlan],
          bought: false,
        }
      );
    }
  }

  return {
    shoppingIngredients: Object.values(shoppingIngredientsByName),
  };
}
