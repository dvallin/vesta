import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ShoppingList, shoppingListSchema } from "../model/shopping-list";
import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";
import { useShoppingList } from "../storage/use-shopping-list";

export default function useShoppingListForm() {
  const shoppingList = useShoppingList();
  const value = getYjsValue(shoppingList) as
    | AbstractType<ShoppingList>
    | undefined;

  const methods = useForm<ShoppingList>({
    mode: "all",
    resolver: zodResolver(shoppingListSchema),
    defaultValues: value?.toJSON() as ShoppingList,
  });

  return methods;
}
