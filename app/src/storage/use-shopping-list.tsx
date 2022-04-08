import { Entity } from "../model/entity";
import { ShoppingList } from "../model/shopping-list";
import { update, add, getSingleton } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

const defaultValue: ShoppingList = { shoppingIngredients: [] };

export function useShoppingList() {
  return useSwrRepository(
    "shopping-list",
    async () => getSingleton<ShoppingList>("shopping-list", defaultValue),
    {
      add: async (list: ShoppingList) => add("shopping-list", list),
      update: async (list: Entity<ShoppingList>) => update(list),
    }
  );
}
