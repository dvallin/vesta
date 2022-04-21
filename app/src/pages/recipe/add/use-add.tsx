import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Recipe, recipeSchema } from "../../../model/recipe";
import { useIonRouter } from "@ionic/react";
import { useRecipes } from "../../../storage/use-recipes";

export default function useAdd() {
  const { add } = useRecipes();

  const router = useIonRouter();

  const methods = useForm<Recipe>({
    mode: "all",
    resolver: zodResolver(recipeSchema),
  });

  const onSubmit = (recipe: Recipe) => {
    const id = add(recipe);
    router.push(`/recipe/${id}`);
  };

  return { methods, onSubmit };
}
