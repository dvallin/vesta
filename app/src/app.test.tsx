import { render } from "@testing-library/react";
import mockStore from "./storage/mock-store";
import App from "./app";

jest.mock("./storage/store", () => ({ store: mockStore() }));

test("renders without crashing", () => {
  const { baseElement } = render(<App />);
  expect(baseElement).toBeDefined();
});
