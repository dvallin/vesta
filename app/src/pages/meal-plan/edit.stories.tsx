import { Story } from "@storybook/react";
import Edit from "./edit";

const Default = {
  title: "pages/meal-plan/Edit",
  component: Edit,
};

const Template: Story = () => <Edit />;

export const StandardRecipe = Template.bind({});

export default Default;
