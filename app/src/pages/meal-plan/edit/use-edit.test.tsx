import { standardMealPlan } from "../../../../.storybook/data/meal-plan";
import { renderHookWithDecorators } from "../../../decorators";
import mockStore from "../../../storage/mock-store";
import useEdit from "./use-edit";

jest.mock("../../../storage/store", () => ({ store: mockStore() }));

const render = () => renderHookWithDecorators(useEdit, undefined, []);

it("initializes state", () => {
  const { result } = render();
  expect(result.current.methods.getValues()).toEqual(standardMealPlan);
});
