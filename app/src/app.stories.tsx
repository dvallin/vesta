import routerDecorator from "../.storybook/decorators/router-decorator";
import App from "./app";

const Default = {
  title: "App",
  component: App,
  decorators: [routerDecorator()],
};

export const Primary = () => <App />;

export default Default;
