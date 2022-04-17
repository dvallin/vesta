import { standardShoppingList } from "../../.storybook/data/shopping-list";
import { renderHookWithDecorators } from "../decorators";
import mockStore from "../storage/mock-store";
import useShoppingListForm from "./use-shopping-list-form";

jest.mock("../storage/store", () => ({ store: mockStore() }));

const render = () =>
  renderHookWithDecorators(useShoppingListForm, undefined, []);

it("initializes state", () => {
  const { result } = render();
  expect(result.current.getValues()).toEqual(standardShoppingList);
});
