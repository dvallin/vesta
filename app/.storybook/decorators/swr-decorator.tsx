import { Story } from "@storybook/react";
import { SWRConfig } from "swr";
import { recipes } from "../data/recipe";
import { mealPlans } from "../data/meal-plan";
import { shoppingLists } from "../data/shopping-list";
import { merge } from "../data/swr-cache";

export default function swrDecorator(
  provider = merge(recipes, mealPlans, shoppingLists)
) {
  return (Story: Story) => (
    <SWRConfig
      value={{
        provider,
        revalidateIfStale: false,
        revalidateOnFocus: false,
      }}
    >
      <Story />
    </SWRConfig>
  );
}
