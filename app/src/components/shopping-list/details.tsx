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
import useShoppingListFields from "../../hooks/use-shopping-list-fields";
import { useToolbar } from "../../hooks/use-toolbar";
import { sortByName } from "../../model/shopping-list";
import ShoppingIngredientItem from "./ingredient/item";

const ShoppingListDetails: React.FC = () => {
  const { todo, bought, toggleBought, clean, reorder } =
    useShoppingListFields();

  const { register } = useToolbar();
  useEffect(() => {
    register("clean-shopping-list", (key) => {
      if (key === "clean") {
        clean();
      }
    });
  });

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
            reorder(detail);
          }}
        >
          {todo
            .sort((a, b) => sortByName(a.ingredient, b.ingredient))
            .map(({ ingredient, index }) => (
              <IonItem key={index} button>
                <IonReorder />
                <ShoppingIngredientItem
                  ingredient={ingredient}
                  onClick={() => {
                    toggleBought(index, ingredient);
                  }}
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
                onClick={() => {
                  toggleBought(index, ingredient);
                }}
              />
            </IonItem>
          ))}
      </IonItemGroup>
    </IonList>
  );
};

export default ShoppingListDetails;
