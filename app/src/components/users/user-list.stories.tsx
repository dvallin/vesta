import { NetworkProvider } from "../../connectivity/use-network";
import UserList from "./user-list";

const Default = {
  title: "UserList",
  component: UserList,
};

export const Primary = () => (
  <NetworkProvider>
    <UserList />
  </NetworkProvider>
);

export default Default;
