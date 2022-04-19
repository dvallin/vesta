import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ShoppingList, shoppingListSchema } from "../../../model/shopping-list";
import { getYjsValue } from "@syncedstore/core";
import { AbstractType } from "yjs";
import { useShoppingList } from "../../../storage/use-shopping-list";
import { useIonRouter } from "@ionic/react";

export default function useEdit() {
  const shoppingList = useShoppingList();
  const value = getYjsValue(shoppingList) as
    | AbstractType<ShoppingList>
    | undefined;

  const methods = useForm<ShoppingList>({
    mode: "all",
    resolver: zodResolver(shoppingListSchema),
    defaultValues: value?.toJSON() as ShoppingList,
  });

  const router = useIonRouter();
  const onSubmit = (updated: ShoppingList) => {
    shoppingList.shoppingIngredients = updated.shoppingIngredients;
    router.goBack();
  };

  return { methods, onSubmit };
}
