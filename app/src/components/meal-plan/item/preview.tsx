import { IonSlide, IonSlides } from "@ionic/react";
import React, { useEffect, useRef } from "react";
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

  const ref = useRef<HTMLIonSlidesElement>(null);
  useEffect(() => {
    const itemIndex = items.findIndex(({ index }) => index === previewIndex);
    if (itemIndex >= 0) {
      void ref.current?.slideTo(itemIndex);
    }
  }, [items, ref, previewIndex]);

  return (
    <IonSlides
      ref={ref}
      pager
      options={{ autoHeight: true }}
      onIonSlideDidChange={async () => {
        const index = await ref.current?.getActiveIndex();
        if (index !== undefined) {
          const newPreviewIndex = items[index].index;
          setPreviewIndex(newPreviewIndex);
        }
      }}
    >
      {items.map(({ item }, index) => (
        // eslint-disable-next-line react/no-array-index-key
        <IonSlide key={index}>
          <MealPlanSummary item={item as MealItem | PreparationItem} />
        </IonSlide>
      ))}
    </IonSlides>
  );
};

export default MealPlanItemPreview;
