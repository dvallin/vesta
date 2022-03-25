import React, { useContext, useState } from "react";

export interface MealPlanItemPreviewContextType {
  setPreviewIndex: (index: number) => void;
  previewIndex: number | undefined;
}

const Context = React.createContext<
  [number | undefined, (index: number) => void]
>([
  undefined,
  () => {
    // default
  },
]);

export const MealPlanItemPreviewContext: React.FC = ({ children }) => {
  // eslint-disable-next-line react/hook-use-state
  const value = useState<number | undefined>();
  return <Context.Provider value={value}>{children}</Context.Provider>;
};

export default function useMealPlanItemPreview() {
  return useContext(Context);
}
