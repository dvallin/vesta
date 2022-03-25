import { standardShoppingList } from "../../.storybook/data/shopping-list";
import { renderHookWithDecorators } from "../decorators";
import { ShoppingList } from "../model/shopping-list";
import useShoppingListForm from "./use-shopping-list-form";

const render = (shoppingList?: ShoppingList) =>
  renderHookWithDecorators(useShoppingListForm, shoppingList, []);

it("initializes state", () => {
  const { result } = render(standardShoppingList);
  expect(result.current.getValues()).toEqual(standardShoppingList);
});

it("resets state", () => {
  const { result, rerender } = render();
  rerender(standardShoppingList);
  expect(result.current.getValues()).toEqual(standardShoppingList);
});
