import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Recipe, recipeSchema } from "../../../model/recipe";
import { useRecipe, useRecipes } from "../../../storage/use-recipes";
import { useParams } from "react-router";
import { useIonRouter } from "@ionic/react";
import { toJson } from "../../../storage/to-json";

export default function useEdit() {
  const { recipeId } = useParams<{ recipeId?: string }>();
  const { update } = useRecipes();

  const recipe = useRecipe(recipeId);
  const methods = useForm<Recipe>({
    mode: "all",
    resolver: zodResolver(recipeSchema),
    defaultValues: recipe ? toJson(recipe) : undefined,
  });

  const router = useIonRouter();
  const onSubmit = (updated: Recipe) => {
    if (recipeId) {
      void update({ ...updated, id: recipeId });
      router.goBack();
    }
  };

  return { methods, onSubmit };
}
