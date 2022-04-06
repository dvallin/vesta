import { Story } from "@storybook/react";

import { NetworkProvider } from "../../src/connectivity/use-network";

export default function networkDecorator(Story: Story) {
  return (
    <NetworkProvider>
      <Story />
    </NetworkProvider>
  );
}
