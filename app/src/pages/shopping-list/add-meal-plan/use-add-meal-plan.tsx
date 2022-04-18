import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  addIngredient,
  ShoppingIngredientFromPlan,
  ShoppingList,
  shoppingListSchema,
} from "../../../model/shopping-list";
import { useMealPlan } from "../../../storage/use-meal-plan";
import { useRecipes } from "../../../storage/use-recipes";
import { useIonRouter } from "@ionic/react";
import { useShoppingList } from "../../../storage/use-shopping-list";

export default function useAddMealPlan() {
  const mealPlan = useMealPlan();
  const { data: recipes } = useRecipes();

  const defaultValues: ShoppingList = { shoppingIngredients: [] };
  for (const p of mealPlan?.plans ?? []) {
    const plan: ShoppingIngredientFromPlan = {
      date: p.date,
      recipeId: p.recipeId,
    };
    const recipe = recipes?.find((r) => p.recipeId === r.id);
    for (const ingredient of recipe?.ingredients ?? []) {
      addIngredient(defaultValues, {
        ...ingredient,
        fromPlans: [plan],
        bought: false,
      });
    }
  }

  const methods = useForm<ShoppingList>({
    mode: "all",
    resolver: zodResolver(shoppingListSchema),
    defaultValues,
  });

  const shoppingList = useShoppingList();
  const router = useIonRouter();
  const onSubmit = (updated: ShoppingList) => {
    for (const ingredient of updated.shoppingIngredients) {
      addIngredient(shoppingList, ingredient);
    }
    router.push("/shopping-list");
  };

  return {
    methods,
    onSubmit,
  };
}
