import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";
import { Entity } from "../model/entity";
import { Recipe } from "../model/recipe";
import { useRecipes } from "../storage/use-recipes";
import useSearch from "./use-search";

export default function useRecipeSearch(term: string, maxCount?: number) {
  const { data: recipes } = useRecipes();
  const value = getYjsValue(recipes) as
    | AbstractType<Entity<Recipe>[]>
    | undefined;

  return useSearch(term, value?.toJSON() as Entity<Recipe>[], {
    maxCount,
    keys: ["name", "ingredients.ingredientName", "facets.value"],
  });
}
