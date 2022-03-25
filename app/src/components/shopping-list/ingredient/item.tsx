import { IonCol, IonGrid, IonRow, IonText } from "@ionic/react";
import { ShoppingIngredient } from "../../../model/shopping-list";

export interface ShoppingIngredientItemProps
  extends React.ComponentPropsWithRef<typeof IonGrid> {
  ingredient: ShoppingIngredient;
}

const ShoppingIngredientItem: React.FC<ShoppingIngredientItemProps> = ({
  ingredient,
  ...props
}) => (
  <IonGrid {...props}>
    <IonRow>
      <IonCol>
        <IonText>
          {ingredient.amount} {ingredient.unit}
        </IonText>
      </IonCol>
      <IonCol>{ingredient.ingredientName}</IonCol>
    </IonRow>
  </IonGrid>
);

export default ShoppingIngredientItem;
