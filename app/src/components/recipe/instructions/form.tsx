import {
  IonButton,
  IonCol,
  IonGrid,
  IonIcon,
  IonItem,
  IonItemOption,
  IonItemOptions,
  IonItemSliding,
  IonLabel,
  IonList,
  IonListHeader,
  IonReorder,
  IonReorderGroup,
  IonRow,
} from "@ionic/react";
import { addOutline } from "ionicons/icons";
import { useFieldArray, useFormContext } from "react-hook-form";
import { Recipe } from "../../../model/recipe";
import TextArea from "../../form/text-area";
import InstructionActionForm from "./action/form";

const InstructionsForm: React.FC = () => {
  const { control } = useFormContext<Recipe>();
  const { fields, append, remove, move } = useFieldArray({
    control,
    name: "instructions",
  });

  return (
    <IonList>
      <IonListHeader color="light">
        <IonLabel>
          <h2>Instructions</h2>
        </IonLabel>
        <IonButton
          color="secondary"
          onClick={() => {
            append({ action: { type: "step" } });
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
                  <IonCol size="4">
                    <InstructionActionForm index={index} />
                  </IonCol>
                  <IonCol>
                    <IonItem lines="none">
                      <TextArea
                        autoGrow
                        name={`instructions.${index}.instruction`}
                        label="instruction"
                      />
                    </IonItem>
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

export default InstructionsForm;
