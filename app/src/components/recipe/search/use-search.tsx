import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";
import { Entity } from "../../../model/entity";
import { Recipe } from "../../../model/recipe";
import { useRecipes } from "../../../storage/use-recipes";
import useGeneralSearch from "../../../hooks/use-search";
import { useState } from "react";

export default function useSearch(maxCount?: number) {
  const [term, setTerm] = useState("");
  const { data: recipes } = useRecipes();
  const value = getYjsValue(recipes) as
    | AbstractType<Entity<Recipe>[]>
    | undefined;

  return {
    result: useGeneralSearch(term, value?.toJSON() as Entity<Recipe>[], {
      maxCount,
      keys: ["name", "ingredients.ingredientName", "facets.value"],
    }),
    term,
    setTerm,
  };
}
