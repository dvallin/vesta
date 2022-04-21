import FormPage from "../../templates/form-page";
import RecipeForm from "../../../components/recipe/form";
import Toolbar from "../../templates/toolbar";
import SubmitButton from "../../templates/toolbar/submit-button";
import RecipeDeleteButton from "../../../components/recipe/delete-button";
import useEdit from "./use-edit";

const Edit: React.FC = () => {
  const { methods, onSubmit } = useEdit();
  return (
    <FormPage
      defaultTitle="Edit Recipe"
      toolbar={
        <Toolbar>
          <RecipeDeleteButton />
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

export default Edit;
