import { Story } from "@storybook/react";
import Edit from ".";

const Default = {
  title: "pages/shopping-list/Edit",
  component: Edit,
  decorators: [],
};

const Template: Story = () => <Edit />;

export const StandardRecipe = Template.bind({});

export default Default;
