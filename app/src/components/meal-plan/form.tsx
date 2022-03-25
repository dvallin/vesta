import {
  IonItem,
  IonItemOption,
  IonItemOptions,
  IonItemSliding,
  IonList,
  IonReorder,
  IonReorderGroup,
} from "@ionic/react";
import { useEffect } from "react";
import RecipeSelect from "../recipe/select";
import useMealPlanFields from "../../hooks/use-meal-plan-fields";
import RecipeLabel from "../recipe/label";
import { useToolbar } from "../../hooks/use-toolbar";
import DayItem from "./list/day-item";
import WeekItem from "./list/week-item";

const MealPlanForm: React.FC = () => {
  const { items, reorder, add, remove } = useMealPlanFields();

  const { register } = useToolbar();
  useEffect(() => {
    register("add-meal-plan", (key) => {
      if (key === "add") {
        add();
      }
    });
  }, [register, add]);

  return (
    <IonList>
      <IonReorderGroup
        disabled={false}
        onIonItemReorder={({ detail }) => {
          reorder(detail);
        }}
      >
        {items.map((item) => {
          switch (item.type) {
            case "week":
              return (
                <WeekItem key={`${item.date}-${item.type}`} date={item.date} />
              );
            case "day":
              return (
                <DayItem key={`${item.date}-${item.type}`} date={item.date} />
              );
            case "preparation":
              return (
                <IonItem key={`${item.date}-${item.type}-${item.plan.id}`}>
                  <RecipeLabel
                    color="secondary"
                    recipeId={item.plan.recipeId}
                  />
                </IonItem>
              );
            case "meal":
              return (
                <IonItemSliding
                  key={`${item.date}-${item.type}-${item.plan.id}`}
                >
                  <IonItemOptions
                    side="start"
                    onIonSwipe={() => {
                      remove(item.index);
                    }}
                  >
                    <IonItemOption expandable color="danger">
                      Delete
                    </IonItemOption>
                  </IonItemOptions>
                  <IonItem>
                    <IonReorder />
                    <RecipeSelect name={`plans.${item.index}.recipeId`} />
                  </IonItem>
                </IonItemSliding>
              );
            default:
              return <></>;
          }
        })}
      </IonReorderGroup>
    </IonList>
  );
};

export default MealPlanForm;
