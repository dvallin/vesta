import { ShoppingList } from "../model/shopping-list";
import { getFirstByType, update, add } from "./repo";
import { useSwrRepository } from "./use-swr-repository";

export function useShoppingList() {
  return useSwrRepository(
    "shopping-list",
    async () => getFirstByType<ShoppingList>("shopping-list"),
    {
      add: async (list: ShoppingList) => add("shopping-list", list),
      update: async (id: string, list: ShoppingList) => update(id, list),
    }
  );
}
