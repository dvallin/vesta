import { IonItem, IonList } from "@ionic/react";
import Input from "../form/input";
import TextArea from "../form/text-area";
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
    </IonList>

    <IngredientsForm />
    <InstructionsForm />
  </>
);

export default RecipeForm;
