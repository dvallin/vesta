import { filterArray, getYjsValue } from "@syncedstore/core";
import { useSyncedStore } from "@syncedstore/react";
import { YArray, YMap } from "yjs/dist/src/internals";
import { ShoppingIngredient } from "../model/shopping-list";
import { store } from "./store";

export function useShoppingList() {
  return useSyncedStore(store).shoppingList;
}

export function useShoppingListIngredients() {
  const shoppingList = useShoppingList();
  const ingredients = shoppingList.shoppingIngredients || [];
  const indexedIngredients =
    ingredients.map((ingredient, index) => ({
      ingredient,
      index,
    })) || [];
  const todo =
    indexedIngredients.filter(({ ingredient }) => !ingredient.bought) || [];
  const bought =
    indexedIngredients.filter(({ ingredient }) => ingredient.bought) || [];

  return {
    todo,
    bought,
    toggle: (index: number) => {
      ingredients[index].bought = !ingredients[index].bought;
    },
    clean: () => {
      filterArray(ingredients, (i) => !i.bought);
    },
    reorder: (from: number, to: number) => {
      const v = getYjsValue(shoppingList.shoppingIngredients) as YArray<
        YMap<ShoppingIngredient>
      >;
      v.doc?.transact(() => {
        const item = v.get(from).clone();
        v.delete(from);
        const adjustedPosition = from < to ? to - 1 : to;
        v.insert(adjustedPosition, [item]);
      });
    },
  };
}
