import { ItemReorderEventDetail } from "@ionic/react";
import { useMemo } from "react";
import { useFieldArray, useFormContext } from "react-hook-form";
import { ShoppingIngredient, ShoppingList } from "../model/shopping-list";

const defaultIngredient = {
  // eslint-disable-next-line unicorn/no-null
  ingredientName: null,
  // eslint-disable-next-line unicorn/no-null
  unit: null,
  // eslint-disable-next-line unicorn/no-null
  amount: null,
  bought: false,
  fromPlans: [],
} as unknown as ShoppingIngredient;

export default function useShoppingListFields() {
  const { control } = useFormContext<ShoppingList>();
  const { fields, update, move, remove, prepend } = useFieldArray({
    control,
    name: "shoppingIngredients",
  });

  const { todo, bought } = useMemo(() => {
    const fieldsWithIndex = fields.map((ingredient, index) => ({
      ingredient,
      index,
    }));
    return {
      todo: fieldsWithIndex.filter(({ ingredient }) => !ingredient.bought),
      bought: fieldsWithIndex.filter(({ ingredient }) => ingredient.bought),
    };
  }, [fields]);

  return {
    todo,
    bought,
    toggleBought: (index: number, ingredient: ShoppingIngredient) => {
      update(index, { ...ingredient, bought: !ingredient.bought });
    },
    clean: () => {
      remove(bought.map(({ index }) => index));
    },
    reorder: ({ from, to, complete }: ItemReorderEventDetail) => {
      move(from, to);
      complete(false);
    },
    add: () => {
      prepend(defaultIngredient);
    },
    remove,
  };
}
