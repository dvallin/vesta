import { IonItem, IonLabel, IonList, IonListHeader } from "@ionic/react";
import { Recipe } from "../../../model/recipe";

export interface RecipeInstructionsProps {
  instructions: Recipe["instructions"];
}

const RecipeInstructions: React.FC<RecipeInstructionsProps> = ({
  instructions,
}) =>
  instructions.length > 0 ? (
    <IonList>
      <IonListHeader>Instructions</IonListHeader>
      {instructions.map((instruction, index) => (
        // eslint-disable-next-line react/no-array-index-key
        <IonItem key={index}>
          <IonLabel className="ion-text-wrap">
            {instruction.instruction}
          </IonLabel>
        </IonItem>
      ))}
    </IonList>
  ) : (
    <></>
  );

export default RecipeInstructions;
