import React, { useContext, useMemo, useState } from "react";

export type Handler = (key: string) => void;
export interface ToolbarContextType {
  register: (id: string, handler: Handler) => void;
  dispatch: (key: string) => void;
  setTitle: (title: string) => void;
  title: string;
}

const Context = React.createContext<ToolbarContextType>({
  register: () => {
    // default
  },
  dispatch: () => {
    // default
  },
  setTitle: () => {
    // default
  },
  title: "",
});

export interface ToolbarProviderProps {
  defaultTitle?: string;
}
export const ToolbarProvider: React.FC<ToolbarProviderProps> = ({
  defaultTitle,
  children,
}) => {
  const [title, setTitle] = useState(defaultTitle ?? "");
  const handlers: Record<string, Handler> = useMemo(() => ({}), []);
  const value = useMemo(
    () => ({
      register(id: string, handler: Handler) {
        handlers[id] = handler;
      },
      dispatch(key: string) {
        for (const h of Object.values(handlers)) {
          h(key);
        }
      },
      setTitle,
      title,
    }),
    [setTitle, title, handlers]
  );
  return <Context.Provider value={value}>{children}</Context.Provider>;
};

export default function useToolbar() {
  return useContext(Context);
}
