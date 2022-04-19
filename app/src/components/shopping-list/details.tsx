import {
  IonItem,
  IonItemDivider,
  IonItemGroup,
  IonLabel,
  IonList,
  IonReorder,
  IonReorderGroup,
} from "@ionic/react";
import { useEffect } from "react";
import useToolbar from "../../pages/templates/toolbar/use-toolbar";
import { sortByName } from "../../model/shopping-list";
import { useShoppingListIngredients } from "../../storage/use-shopping-list";
import ShoppingIngredientItem from "./ingredient/item";

const ShoppingListDetails: React.FC = () => {
  const { todo, bought, toggle, clean, reorder } = useShoppingListIngredients();

  const { register } = useToolbar();
  useEffect(() => {
    register("clean-shopping-list", (key) => {
      if (key === "clean") {
        clean();
      }
    });
  }, [register, clean]);

  return (
    <IonList>
      <IonItemGroup>
        <IonItemDivider>
          <IonLabel>
            Todo ({bought.length} / {todo.length + bought.length})
          </IonLabel>
        </IonItemDivider>
        <IonReorderGroup
          disabled={false}
          onIonItemReorder={({ detail }) => {
            reorder(detail.from, detail.to);
            detail.complete(false);
          }}
        >
          {todo.map(({ ingredient, index }) => (
            <IonItem key={index} button>
              <IonReorder />
              <ShoppingIngredientItem
                ingredient={ingredient}
                onClick={() => toggle(index)}
              />
            </IonItem>
          ))}
        </IonReorderGroup>
      </IonItemGroup>
      <IonItemGroup>
        <IonItemDivider>
          <IonLabel>Bought</IonLabel>
        </IonItemDivider>
        {bought
          .sort((a, b) => sortByName(a.ingredient, b.ingredient))
          .map(({ ingredient, index }) => (
            <IonItem key={index} button>
              <ShoppingIngredientItem
                ingredient={ingredient}
                onClick={() => toggle(index)}
              />
            </IonItem>
          ))}
      </IonItemGroup>
    </IonList>
  );
};

export default ShoppingListDetails;
