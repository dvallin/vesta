import { filterArray } from "@syncedstore/core";
import { useSyncedStore } from "@syncedstore/react";
import { useCallback } from "react";
import { v4 } from "uuid";
import { Entity } from "../model/entity";
import { Recipe } from "../model/recipe";
import { store } from "./store";

export function useRecipes() {
  const { recipes } = useSyncedStore(store);

  const remove = useCallback(
    (id: string) => {
      filterArray(recipes, (r) => r.id !== id);
    },
    [recipes]
  );

  const update = useCallback(
    (recipe: Entity<Recipe>) => {
      filterArray(recipes, (r) => r.id !== recipe.id);
      recipes.push(recipe);
    },
    [recipes]
  );

  const add = useCallback(
    (recipe: Recipe) => recipes.push({ id: v4(), ...recipe }),
    [recipes]
  );

  return {
    data: recipes,
    add,
    remove,
    update,
  };
}

export function useRecipe(id: string | undefined): Entity<Recipe> | undefined {
  const { data } = useRecipes();
  return data.find((r) => r.id === id);
}
