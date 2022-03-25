import { Story } from "@storybook/react";
import swrDecorator from "../../../.storybook/decorators/swr-decorator";
import View from "./view";

const Default = {
  title: "pages/meal-plan/View",
  component: View,
  decorators: [swrDecorator()],
};

const Template: Story = () => <View />;

export const StandardPlan = Template.bind({});

export default Default;
