import { IonButton, IonCol, IonGrid, IonIcon, IonRow } from "@ionic/react";
import { chevronBackOutline, chevronForwardOutline } from "ionicons/icons";
import MealPlanSummary from "../summary";
import usePreview from "./use-preview";

const MealPlanItemPreview: React.FC = () => {
  const { onPrev, current, onNext } = usePreview();

  if (!current) {
    return <></>;
  }

  return (
    <IonGrid>
      <IonRow className="ion-align-items-center">
        <IonCol size="2">
          <IonButton color="light" onClick={onPrev}>
            <IonIcon icon={chevronBackOutline} />
          </IonButton>
        </IonCol>
        <IonCol size="8">
          <MealPlanSummary item={current} />
        </IonCol>
        <IonCol size="2">
          <IonButton color="light" onClick={onNext}>
            <IonIcon icon={chevronForwardOutline} />
          </IonButton>
        </IonCol>
      </IonRow>
    </IonGrid>
  );
};

export default MealPlanItemPreview;
