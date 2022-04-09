import { Story } from "@storybook/react";
import View from "./view";

const Default = {
  title: "pages/meal-plan/View",
  component: View,
  decorators: [],
};

const Template: Story = () => <View />;

export const StandardPlan = Template.bind({});

export default Default;
