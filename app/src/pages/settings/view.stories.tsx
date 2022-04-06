import { Story } from "@storybook/react";
import networkDecorator from "../../../.storybook/decorators/network-decorator";
import swrDecorator from "../../../.storybook/decorators/swr-decorator";
import View from "./view";

const Default = {
  title: "pages/settings/View",
  component: View,
  decorators: [swrDecorator(), networkDecorator],
};

const Template: Story = () => <View />;

export const StandardRecipe = Template.bind({});

export default Default;
