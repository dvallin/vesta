import { IonItem, IonList, IonNote } from "@ionic/react";
import useMealPlanItemPreview from "../../hooks/use-meal-plan-item-preview";
import useMealPlanWeekView from "../../hooks/use-meal-plan-week-view";
import RecipeLabel from "../recipe/label";
import DayItem from "./list/day-item";
import WeekItem from "./list/week-item";

const MealPlanDetails: React.FC = () => {
  const list = useMealPlanWeekView();
  const [previewIndex, setPreviewIndex] = useMealPlanItemPreview();
  return (
    <IonList>
      {list.map((item, index) => {
        const key = index;
        switch (item.type) {
          case "week":
            return <WeekItem key={key} date={item.date} />;
          case "day":
            return <DayItem key={key} date={item.date} />;
          case "preparation":
            return (
              <IonItem key={key} button>
                <IonNote slot="start">{item.instructions.length} tasks</IonNote>
                <RecipeLabel
                  color={previewIndex === index ? "success" : "secondary"}
                  recipeId={item.plan.recipeId}
                  onClick={() => {
                    setPreviewIndex(index);
                  }}
                />
              </IonItem>
            );
          case "meal":
            return (
              <IonItem key={key} button>
                <IonNote slot="start">{item.instructions.length} tasks</IonNote>
                <RecipeLabel
                  color={previewIndex === index ? "success" : "primary"}
                  recipeId={item.plan.recipeId}
                  onClick={() => {
                    setPreviewIndex(index);
                  }}
                />
              </IonItem>
            );
          default:
            return <></>;
        }
      })}
    </IonList>
  );
};

export default MealPlanDetails;
