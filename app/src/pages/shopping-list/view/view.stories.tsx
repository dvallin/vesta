import { Story } from "@storybook/react";
import View from ".";

const Default = {
  title: "pages/shopping-list/View",
  component: View,
  decorators: [],
};

const Template: Story = () => <View />;

export const StandardPlan = Template.bind({});

export default Default;
