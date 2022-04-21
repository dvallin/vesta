import { ItemReorderEventDetail } from "@ionic/react";
import { startOfToday } from "date-fns";
import { useMemo } from "react";
import { useFieldArray, useFormContext } from "react-hook-form";
import {
  DailyMealPlan,
  MealPlan,
  buildPlanItems,
} from "../../../model/meal-plan";
import { useRecipes } from "../../../storage/use-recipes";

export default function useForm() {
  const { control, getValues } = useFormContext<MealPlan>();
  const { fields, replace, insert, remove } = useFieldArray({
    control,
    name: "plans",
  });
  const { data: recipes } = useRecipes();

  const items = useMemo(
    () => buildPlanItems(fields, recipes),
    [fields, recipes]
  );

  const minimumInsertIndex =
    items.findIndex(
      (i) => i.type === "day" && i.date >= startOfToday().getTime()
    ) + 1;

  return {
    items,
    add: () => {
      insert(minimumInsertIndex, { date: startOfToday().getTime() });
    },
    remove: (index: number) => {
      remove(index);
    },
    reorder: ({ from, to, complete }: ItemReorderEventDetail) => {
      const item = items[from];
      // We only drag meal lines
      if (item.type !== "meal") {
        return;
      }

      // Update items
      items.splice(from, 1);
      items.splice(Math.max(to, minimumInsertIndex), 0, item);

      // Rebuild fields
      let date = 0;
      const newFields: DailyMealPlan[] = [];
      for (const line of items) {
        switch (line.type) {
          case "day":
          case "week":
            date = line.date;
            break;
          case "meal":
            newFields.push({
              ...getValues(`plans.${line.index}`),
              date,
            });
            break;
          default:
            break;
        }
      }

      // Replace fields
      replace(newFields);

      // Complete and tell ionic WE updated the data, because rhf will rerender
      complete(false);
    },
  };
}
