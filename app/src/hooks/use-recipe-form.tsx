import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
import { Recipe, recipeSchema } from "../model/recipe";

export default function useRecipeForm(recipe?: Recipe) {
  const methods = useForm<Recipe>({
    mode: "all",
    resolver: zodResolver(recipeSchema),
  });

  useEffect(() => {
    if (recipe) {
      methods.reset(recipe);
    }
  }, [recipe, methods]);

  return methods;
}
