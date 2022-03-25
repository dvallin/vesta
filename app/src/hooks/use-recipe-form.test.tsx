import { standardRecipe } from "../../.storybook/data/recipe";
import { renderHookWithDecorators } from "../decorators";
import { Recipe } from "../model/recipe";
import useRecipeForm from "./use-recipe-form";

const render = (recipe?: Recipe) =>
  renderHookWithDecorators(useRecipeForm, recipe, []);

it("initializes state", () => {
  const { result } = render(standardRecipe);
  expect(result.current.getValues()).toEqual(standardRecipe);
});

it("resets state", () => {
  const { result, rerender } = render();
  rerender(standardRecipe);
  expect(result.current.getValues()).toEqual(standardRecipe);
});
