import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Recipe, recipeSchema } from "../../../model/recipe";
import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";
import { useRecipe, useRecipes } from "../../../storage/use-recipes";
import { useParams } from "react-router";
import { useIonRouter } from "@ionic/react";

export default function useEdit() {
  const { recipeId } = useParams<{ recipeId?: string }>();
  const { update } = useRecipes();

  const recipe = useRecipe(recipeId);
  const value = getYjsValue(recipe) as AbstractType<Recipe> | undefined;

  const router = useIonRouter();

  const methods = useForm<Recipe>({
    mode: "all",
    resolver: zodResolver(recipeSchema),
    defaultValues: value?.toJSON() as Recipe,
  });

  const onSubmit = (updated: Recipe) => {
    if (recipeId) {
      void update({ ...updated, id: recipeId });
      router.goBack();
    }
  };

  return { methods, onSubmit };
}
