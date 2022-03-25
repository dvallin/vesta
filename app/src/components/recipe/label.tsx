import { IonLabel, IonItem } from "@ionic/react";
import React from "react";
import { useRecipe } from "../../storage/use-recipes";

export interface RecipeLabelProps
  extends React.ComponentPropsWithRef<typeof IonItem> {
  recipeId: string;
  defaultLabel?: string;
}

const RecipeLabel: React.FC<RecipeLabelProps> = ({
  recipeId,
  defaultLabel,
  ...rest
}) => {
  const recipe = useRecipe(recipeId);

  return <IonLabel {...rest}>{recipe?.name ?? defaultLabel}</IonLabel>;
};

export default RecipeLabel;
