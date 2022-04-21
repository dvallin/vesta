import { MealItem, PreparationItem } from "../../../../model/meal-plan";
import useMealPlanItemPreview from "../../use-meal-plan-item-preview";
import useMealPlanWeekView from "../../use-meal-plan-week-view";

export default function usePreview() {
  const [previewIndex, setPreviewIndex] = useMealPlanItemPreview();
  const list = useMealPlanWeekView();
  const items = list
    .map((item, index) => ({ item, index }))
    .filter(({ item }) => item.type === "preparation" || item.type === "meal");

  let currentItemIndex = items.findIndex(({ index }) => index === previewIndex);
  if (currentItemIndex < 0) {
    currentItemIndex = 0;
  }

  return {
    onPrev: () =>
      setPreviewIndex(
        items[(currentItemIndex + items.length - 1) % items.length].index
      ),
    current: items[currentItemIndex]?.item as MealItem | PreparationItem,
    onNext: () =>
      setPreviewIndex(items[(currentItemIndex + 1) % items.length].index),
  };
}
