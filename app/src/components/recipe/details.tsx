import {
  IonCard,
  IonCardContent,
  IonCardHeader,
  IonCardTitle,
  IonChip,
  IonLabel,
  IonText,
} from "@ionic/react";
import { useRecipe } from "../../storage/use-recipes";
import RecipeIngredients from "./ingredients/list";
import RecipeInstructions from "./instructions/list";

export interface RecipeDetailsProps {
  recipeId: string;
}

const RecipeDetails: React.FC<RecipeDetailsProps> = ({ recipeId }) => {
  const recipe = useRecipe(recipeId);
  return (
    <IonCard>
      <IonCardHeader>
        <IonCardTitle>{recipe?.name}</IonCardTitle>
      </IonCardHeader>
      <IonCardContent>
        {recipe?.facets?.map(({ key, value, icon }) => (
          <IonChip key={`${key}:${value}`}>
            <IonLabel>
              {value} {icon}
            </IonLabel>
          </IonChip>
        ))}

        <IonText>
          <p>{recipe?.description}</p>
        </IonText>

        <RecipeIngredients ingredients={recipe?.ingredients ?? []} />
        <RecipeInstructions instructions={recipe?.instructions ?? []} />
      </IonCardContent>
    </IonCard>
  );
};

export default RecipeDetails;
