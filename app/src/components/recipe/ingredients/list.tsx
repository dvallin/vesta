import {
  IonCol,
  IonGrid,
  IonItem,
  IonList,
  IonListHeader,
  IonRow,
} from "@ionic/react";
import { Recipe } from "../../../model/recipe";

export interface RecipeIngredientsProps {
  ingredients: Recipe["ingredients"];
}

const RecipeIngredients: React.FC<RecipeIngredientsProps> = ({ ingredients }) =>
  ingredients.length > 0 ? (
    <IonList>
      <IonListHeader>Ingredients</IonListHeader>
      {ingredients.map((ingredient, index) => (
        // eslint-disable-next-line react/no-array-index-key
        <IonItem key={index}>
          <IonGrid>
            <IonRow>
              <IonCol>
                {ingredient.amount} {ingredient.unit}
              </IonCol>
              <IonCol>{ingredient.ingredientName}</IonCol>
            </IonRow>
          </IonGrid>
        </IonItem>
      ))}
    </IonList>
  ) : (
    <></>
  );

export default RecipeIngredients;
