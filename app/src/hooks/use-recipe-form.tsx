import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Recipe, recipeSchema } from "../model/recipe";
import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";
import { useRecipe } from "../storage/use-recipes";

export default function useRecipeForm(recipeId?: string) {
  const recipe = useRecipe(recipeId);
  const value = getYjsValue(recipe) as AbstractType<Recipe> | undefined;

  const methods = useForm<Recipe>({
    mode: "all",
    resolver: zodResolver(recipeSchema),
    defaultValues: value?.toJSON() as Recipe,
  });

  return methods;
}
