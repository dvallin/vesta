import { Story } from "@storybook/react";
import TitledPage from "../../src/pages/templates/titled-page";

export default function pageDecorator(Story: Story) {
  return (
    <TitledPage title="Story Page">
      <Story />
    </TitledPage>
  );
}
