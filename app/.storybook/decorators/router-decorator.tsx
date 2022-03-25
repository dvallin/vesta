import { Story } from "@storybook/react";
import { createBrowserHistory } from "history";
import { Route, Router } from "react-router";

export default function routerDecorator(url?: string, path?: string) {
  return (Story: Story) => {
    if (url) {
      window.history.pushState({}, "", url);
    }
    return (
      <Router history={createBrowserHistory()}>
        <Route path={path}>
          <Story />
        </Route>
      </Router>
    );
  };
}
