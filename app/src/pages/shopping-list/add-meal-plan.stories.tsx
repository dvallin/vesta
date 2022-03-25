import { Story } from "@storybook/react";
import swrDecorator from "../../../.storybook/decorators/swr-decorator";
import AddMealPlan from "./add-meal-plan";

const Default = {
  title: "pages/shopping-list/AddMealPlan",
  component: AddMealPlan,
  decorators: [swrDecorator()],
};

const Template: Story = () => <AddMealPlan />;

export const StandardRecipe = Template.bind({});

export default Default;
