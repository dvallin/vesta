import routerDecorator from "../.storybook/decorators/router-decorator";
import swrDecorator from "../.storybook/decorators/swr-decorator";
import App from "./app";

const Default = {
  title: "App",
  component: App,
  decorators: [routerDecorator(), swrDecorator()],
};

export const Primary = () => <App />;

export default Default;
