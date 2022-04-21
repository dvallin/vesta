import {
  IonCol,
  IonGrid,
  IonItem,
  IonItemOption,
  IonItemOptions,
  IonItemSliding,
  IonList,
  IonReorder,
  IonReorderGroup,
  IonRow,
} from "@ionic/react";
import useForm from "./use-form";
import NumberInput from "../../form/number-input";
import IngredientNameInput from "../../form/suggestion-inputs/ingredient-name-input";
import UnitInput from "../../form/suggestion-inputs/unit-input";

const ShoppingListDetails: React.FC = () => {
  const { todo, reorder, remove } = useForm();

  return (
    <IonList>
      <IonReorderGroup
        disabled={false}
        onIonItemReorder={({ detail }) => {
          reorder(detail);
        }}
      >
        {todo.map(({ index, ingredient }) => (
          <IonItemSliding key={ingredient.id}>
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
              <IonReorder />
              <IonGrid>
                <IonRow color="light">
                  <IonCol>
                    <NumberInput
                      name={`shoppingIngredients.${index}.amount`}
                      label="Amount"
                    />
                  </IonCol>
                  <IonCol>
                    <UnitInput name={`shoppingIngredients.${index}.unit`} />
                  </IonCol>
                  <IonCol>
                    <IngredientNameInput
                      name={`shoppingIngredients.${index}.ingredientName`}
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

export default ShoppingListDetails;
