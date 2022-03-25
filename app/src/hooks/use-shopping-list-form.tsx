import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
import { ShoppingList, shoppingListSchema } from "../model/shopping-list";

export default function useShoppingListForm(list?: ShoppingList) {
  const methods = useForm<ShoppingList>({
    mode: "all",
    resolver: zodResolver(shoppingListSchema),
  });

  useEffect(() => {
    if (list) {
      methods.reset(list);
    }
  }, [list, methods]);

  return methods;
}
