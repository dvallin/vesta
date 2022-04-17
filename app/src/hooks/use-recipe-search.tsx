import { useRecipes } from "../storage/use-recipes";
import useSearch from "./use-search";

export default function useRecipeSearch(term: string, maxCount?: number) {
  const { data: recipes } = useRecipes();
  return useSearch(term, recipes, {
    maxCount,
    keys: ["name", "ingredients.ingredientName"],
  });
}
