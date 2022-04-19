import FormPage from "../../templates/form-page";
import RecipeForm from "../../../components/recipe/form";
import Toolbar from "../../templates/toolbar";
import SubmitButton from "../../templates/toolbar/submit-button";
import useAdd from "./use-add";

const Add: React.FC = () => {
  const { methods, onSubmit } = useAdd();
  return (
    <FormPage
      defaultTitle="Add Recipe"
      toolbar={
        <Toolbar>
          <SubmitButton />
        </Toolbar>
      }
      methods={methods}
      onSubmit={onSubmit}
    >
      <RecipeForm />
    </FormPage>
  );
};

export default Add;
