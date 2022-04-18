import { IonCol, IonGrid, IonItem, IonList, IonRow } from "@ionic/react";
import Input from "../form/input";
import TextArea from "../form/text-area";
import CountrySelect from "./facet-selectors/country-select";
import DietSelect from "./facet-selectors/diet-select";
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
                <DietSelect />
              </IonItem>
            </IonCol>
            <IonCol size="6">
              <IonItem lines="none">
                <CountrySelect />
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
