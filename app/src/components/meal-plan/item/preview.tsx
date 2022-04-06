import { IonButton, IonCol, IonGrid, IonIcon, IonRow } from "@ionic/react";
import { chevronBackOutline, chevronForwardOutline } from "ionicons/icons";
import useMealPlanItemPreview from "../../../hooks/use-meal-plan-item-preview";
import useMealPlanWeekView from "../../../hooks/use-meal-plan-week-view";
import { MealItem, PreparationItem } from "../../../model/meal-plan";
import MealPlanSummary from "./summary";

const MealPlanItemPreview: React.FC = () => {
  const [previewIndex, setPreviewIndex] = useMealPlanItemPreview();
  const list = useMealPlanWeekView();
  const items = list
    .map((item, index) => ({ item, index }))
    .filter(({ item }) => item.type === "preparation" || item.type === "meal");

  if (items.length === 0) {
    return <></>;
  }

  let currentItemIndex = items.findIndex(({ index }) => index === previewIndex);
  if (currentItemIndex < 0) {
    currentItemIndex = 0;
  }
  console.log(currentItemIndex, previewIndex, items[currentItemIndex]);
  return (
    <>
      <IonGrid>
        <IonRow className="ion-align-items-center">
          <IonCol size="2">
            <IonButton
              color="light"
              onClick={() =>
                setPreviewIndex(
                  items[(currentItemIndex + items.length - 1) % items.length]
                    .index
                )
              }
            >
              <IonIcon icon={chevronBackOutline} />
            </IonButton>
          </IonCol>
          <IonCol size="8">
            <MealPlanSummary
              item={items[currentItemIndex].item as MealItem | PreparationItem}
            />
          </IonCol>
          <IonCol size="2">
            <IonButton
              color="light"
              onClick={() =>
                setPreviewIndex(
                  items[(currentItemIndex + 1) % items.length].index
                )
              }
            >
              <IonIcon icon={chevronForwardOutline} />
            </IonButton>
          </IonCol>
        </IonRow>
      </IonGrid>
    </>
  );
};

export default MealPlanItemPreview;
