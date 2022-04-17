import { standardRecipe } from "../../.storybook/data/recipe";
import { renderHookWithDecorators } from "../decorators";
import mockStore from "../storage/mock-store";
import useRecipeForm from "./use-recipe-form";

jest.mock("../storage/store", () => ({ store: mockStore() }));

const render = () =>
  renderHookWithDecorators(useRecipeForm, standardRecipe.id, []);

it("initializes state", () => {
  const { result } = render();
  expect(result.current.getValues()).toEqual(standardRecipe);
});
