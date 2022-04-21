import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ShoppingList, shoppingListSchema } from "../../../model/shopping-list";
import { useShoppingList } from "../../../storage/use-shopping-list";
import { useIonRouter } from "@ionic/react";
import { toJson } from "../../../storage/to-json";
export default function useEdit() {
  const shoppingList = useShoppingList();

  const methods = useForm<ShoppingList>({
    mode: "all",
    resolver: zodResolver(shoppingListSchema),
    defaultValues: toJson(shoppingList),
  });

  const router = useIonRouter();
  const onSubmit = (updated: ShoppingList) => {
    shoppingList.shoppingIngredients = updated.shoppingIngredients;
    router.goBack();
  };

  return { methods, onSubmit };
}
