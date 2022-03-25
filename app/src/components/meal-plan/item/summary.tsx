import { IonCard, IonCardContent, IonCardHeader } from "@ionic/react";
import { MealItem, PreparationItem } from "../../../model/meal-plan";
import { useRecipe } from "../../../storage/use-recipes";
import RecipeIngredients from "../../recipe/ingredients/list";
import RecipeInstructions from "../../recipe/instructions/list";

export interface MealPlanItemSummaryProps {
  item: MealItem | PreparationItem;
}

const MealPlanItemSummary: React.FC<MealPlanItemSummaryProps> = ({ item }) => {
  const recipe = useRecipe(item.plan.recipeId);
  return (
    <IonCard button routerLink={`/recipe/${item.plan.recipeId}`}>
      <IonCardHeader>{recipe?.name}</IonCardHeader>
      <IonCardContent>
        <RecipeIngredients ingredients={recipe?.ingredients ?? []} />
        <RecipeInstructions instructions={item.instructions} />
      </IonCardContent>
    </IonCard>
  );
};

export default MealPlanItemSummary;
