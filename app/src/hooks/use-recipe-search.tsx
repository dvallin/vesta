import { useRecipes } from "../storage/use-recipes";
import useSearch from "./use-search";

export default function useRecipeSearch(term: string, maxCount?: number) {
  const { data = [] } = useRecipes();
  return useSearch(term, data, {
    maxCount,
    keys: ["name", "ingredients.ingredientName"],
  });
}
