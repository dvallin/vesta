import { ItemReorderEventDetail } from "@ionic/react";
import { useEffect, useMemo } from "react";
import { useFieldArray, useFormContext } from "react-hook-form";
import useToolbar from "../../../pages/templates/toolbar/use-toolbar";
import { ShoppingIngredient, ShoppingList } from "../../../model/shopping-list";

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

export default function useForm() {
  const { control } = useFormContext<ShoppingList>();
  const { fields, move, remove, prepend } = useFieldArray({
    control,
    name: "shoppingIngredients",
  });

  const { register } = useToolbar();
  useEffect(() => {
    register("clean-shopping-list", (key) => {
      if (key === "add") {
        prepend(defaultIngredient);
      }
    });
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
    reorder: ({ from, to, complete }: ItemReorderEventDetail) => {
      move(from, to);
      complete(false);
    },
    remove,
  };
}
