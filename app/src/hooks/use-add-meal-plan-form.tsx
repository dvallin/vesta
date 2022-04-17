import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  createShoppingListFromMealPlan,
  ShoppingList,
  shoppingListSchema,
} from "../model/shopping-list";
import { useMealPlan } from "../storage/use-meal-plan";
import { useRecipes } from "../storage/use-recipes";

export default function useAddMealPlanForm() {
  const mealPlan = useMealPlan();
  const { data: recipes } = useRecipes();

  const shoppingList = createShoppingListFromMealPlan(mealPlan, recipes);

  const methods = useForm<ShoppingList>({
    mode: "all",
    resolver: zodResolver(shoppingListSchema),
    defaultValues: shoppingList,
  });

  return methods;
}
