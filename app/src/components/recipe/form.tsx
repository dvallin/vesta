import { IonCol, IonGrid, IonItem, IonList, IonRow } from "@ionic/react";
import Input from "../form/input";
import TextArea from "../form/text-area";
import CountryEdit from "./facets/edit/country-edit";
import DietEdit from "./facets/edit/diet-edit";
import IngredientsForm from "./ingredients/form";
import InstructionsForm from "./instructions/form";

const RecipeForm: React.FC = () => (
  <>
    <IonList>
      <IonItem>
        <Input name="name" label="Name" type="text" />
      </IonItem>
      <IonItem>
        <TextArea autoGrow name="description" label="Description" />
      </IonItem>
      <IonItem>
        <IonGrid>
          <IonRow>
            <IonCol size="6">
              <IonItem lines="none">
                <DietEdit />
              </IonItem>
            </IonCol>
            <IonCol size="6">
              <IonItem lines="none">
                <CountryEdit />
              </IonItem>
            </IonCol>
          </IonRow>
        </IonGrid>
      </IonItem>
    </IonList>

    <IngredientsForm />
    <InstructionsForm />
  </>
);

export default RecipeForm;
