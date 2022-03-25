import { Entity } from "../model/entity";
import { Recipe } from "../model/recipe";
import { getAllByType, add, update } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

export function useRecipes() {
  return useSwrRepository(
    "recipes",
    async () => getAllByType<Recipe>("recipe"),
    {
      add: async (recipe: Recipe) => add("recipe", recipe),
      update: async (id: string, recipe: Recipe) => update(id, recipe),
    }
  );
}

export function useRecipe(id: string | undefined): Entity<Recipe> | undefined {
  const { data: recipes = [] } = useRecipes();
  return recipes.find((r) => r.id === id);
}
