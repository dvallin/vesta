import {
  IonButton,
  IonListHeader,
  IonItem,
  IonList,
  IonLabel,
  IonGrid,
  IonRow,
  IonCol,
  IonItemSliding,
  IonItemOptions,
  IonItemOption,
  IonReorderGroup,
  IonReorder,
  IonIcon,
} from "@ionic/react";
import { useFieldArray, useFormContext } from "react-hook-form";
import { addOutline } from "ionicons/icons";
import { Recipe } from "../../../model/recipe";
import IngredientNameInput from "../../form/suggestion-inputs/ingredient-name-input";
import NumberInput from "../../form/number-input";
import UnitInput from "../../form/suggestion-inputs/unit-input";

const IngredientsForm: React.FC = () => {
  const { control } = useFormContext<Recipe>();
  const { fields, append, remove, move } = useFieldArray({
    control,
    name: "ingredients",
  });

  return (
    <IonList>
      <IonListHeader color="light">
        <IonLabel>
          <h2>Ingredients</h2>
        </IonLabel>
        <IonButton
          color="secondary"
          onClick={() => {
            append({});
          }}
        >
          <IonIcon icon={addOutline} />
        </IonButton>
      </IonListHeader>

      <IonReorderGroup
        disabled={false}
        onIonItemReorder={({ detail: { from, to, complete } }) => {
          move(from, to);
          complete(false);
        }}
      >
        {fields.map(({ id }, index) => (
          <IonItemSliding key={id}>
            <IonItemOptions
              side="start"
              onIonSwipe={() => {
                remove(index);
              }}
            >
              <IonItemOption expandable color="danger">
                Delete
              </IonItemOption>
            </IonItemOptions>
            <IonItem>
              <IonGrid>
                <IonRow>
                  <IonCol size="1">
                    <IonReorder />
                  </IonCol>
                  <IonCol>
                    <NumberInput
                      name={`ingredients.${index}.amount`}
                      label="Amount"
                    />
                  </IonCol>
                  <IonCol>
                    <UnitInput name={`ingredients.${index}.unit`} />
                  </IonCol>
                  <IonCol>
                    <IngredientNameInput
                      name={`ingredients.${index}.ingredientName`}
                    />
                  </IonCol>
                </IonRow>
              </IonGrid>
            </IonItem>
          </IonItemSliding>
        ))}
      </IonReorderGroup>
    </IonList>
  );
};

export default IngredientsForm;
