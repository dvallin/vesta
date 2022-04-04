import Peer from "peerjs";
import React, {
  createContext,
  Reducer,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useReducer,
  useState,
} from "react";
import usePeerClient from "./use-peer-client";

type Connectivity = {
  peers: {
    [id: string]: {
      connection: Peer.DataConnection | undefined;
      username: string | undefined;
    };
  };
  events: ConnectivityAction[];
};

type ConnectivityAction =
  | {
      type: "clear-events";
    }
  | {
      type: "set-name";
      id: string;
      username: string | undefined;
    }
  | {
      type: "data";
      id: string;
      data: Record<string, unknown>;
    }
  | {
      type: "connect";
      id: string;
      connection: Peer.DataConnection;
    }
  | {
      type: "disconnect";
      id: string;
    }
  | {
      type: "forget";
      id: string;
    };

const reducer: Reducer<Connectivity, ConnectivityAction> = (state, action) => {
  switch (action.type) {
    case "clear-events": {
      return {
        peers: state.peers,
        events: [],
      };
    }
    case "data": {
      return {
        peers: state.peers,
        events: [...state.events, action],
      };
    }
    case "set-name": {
      return {
        peers: {
          ...state.peers,
          [action.id]: { ...state.peers[action.id], username: action.username },
        },
        events: [...state.events, action],
      };
    }
    case "connect":
      return {
        peers: {
          ...state.peers,
          [action.id]: {
            ...state.peers[action.id],
            connection: action.connection,
          },
        },
        events: [...state.events, action],
      };
    case "disconnect":
      return {
        peers: {
          ...state.peers,
          [action.id]: { ...state.peers[action.id], connection: undefined },
        },
        events: [...state.events, action],
      };
    case "forget": {
      const peers = {
        ...state.peers,
      };
      delete peers[action.id];
      return {
        peers,
        events: [...state.events, action],
      };
    }
  }
};

const fail = () => {
  throw new Error("context not initialized");
};
const Context = createContext<Network>({
  peers: [],
  connect: fail,
  disconnect: fail,
  forget: fail,
  send: fail,
  broadcast: fail,
  on: fail,
  off: fail,
  setPeerUsername: fail,
});

function useNetworkProvider() {
  const peer = usePeerClient();
  const [state, dispatch] = useReducer(reducer, { peers: {}, events: [] });
  const [dataHandlers, setDataHandlers] = useState<DataHandler[]>([]);
  const [connectHandlers, setConnectHandlers] = useState<ConnectHandler[]>([]);

  const peers = useMemo(
    () =>
      Object.entries(state.peers).map(([id, { connection, username }]) => ({
        id,
        online: connection !== undefined,
        username,
      })),
    [state.peers]
  );

  const setPeerUsername = useCallback(
    (id: string, username: string | undefined) =>
      dispatch({ type: "set-name", id, username }),
    [dispatch]
  );

  const disconnect = useCallback(
    (id: string) => {
      state.peers[id]?.connection?.close();
    },
    [state]
  );

  const forget = useCallback(
    (id: string) => {
      disconnect(id);
      dispatch({ type: "forget", id });
    },
    [disconnect, dispatch]
  );

  const send = useCallback(
    (id: string, data: Record<string, unknown>) =>
      state.peers[id]?.connection?.send(data),
    [state]
  );

  const registerConnection = useCallback(
    (connection: Peer.DataConnection) =>
      new Promise<Peer.DataConnection>((resolve) => {
        const id = connection.peer;
        connection.on("open", () => {
          dispatch({ type: "connect", id, connection });
          resolve(connection);
        });
        connection.on("data", (data: Record<string, unknown>) => {
          dispatch({ type: "data", id, data });
        });
        connection.on("close", () => {
          dispatch({ type: "disconnect", id });
        });
      }),
    []
  );

  const connect = useCallback(
    (id: string): Promise<Peer.DataConnection> => {
      if (!peer) {
        return Promise.reject(new Error("network not ready"));
      }
      const c = state.peers[id]?.connection;
      if (c === undefined) {
        const conn = peer.connect(id);
        return registerConnection(conn);
      }
      return Promise.resolve(c);
    },
    [peer, state, registerConnection]
  );

  useEffect(() => {
    if (peer) {
      const onConnection = (conn: Peer.DataConnection) =>
        void registerConnection(conn);

      peer.on("connection", onConnection);
      return () => peer.off("connection", onConnection);
    }
  }, [peer, connectHandlers, dataHandlers, registerConnection]);

  const broadcast = useCallback(
    (data: Record<string, unknown>) =>
      Object.keys(state).map((id) => send(id, data)),
    [state, send]
  );

  const on = useCallback(
    (event: "data" | "connect", handler: DataHandler | ConnectHandler) =>
      event === "data"
        ? setDataHandlers([...dataHandlers, handler as DataHandler])
        : setConnectHandlers([...connectHandlers, handler as ConnectHandler]),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const off = useCallback(
    (event: "data" | "connect", handler: DataHandler | ConnectHandler) =>
      event === "data"
        ? setDataHandlers(dataHandlers.filter((h) => h !== handler))
        : setConnectHandlers(connectHandlers.filter((h) => h !== handler)),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  const network = useMemo(
    () => ({
      peers,
      connect,
      disconnect,
      forget,
      send,
      broadcast,
      on,
      off,
      setPeerUsername,
    }),
    [
      peers,
      connect,
      disconnect,
      forget,
      send,
      broadcast,
      on,
      off,
      setPeerUsername,
    ]
  );

  useEffect(() => {
    if (state.events.length > 0) {
      for (const event of state.events) {
        switch (event.type) {
          case "connect": {
            const applicableHandlers = connectHandlers.filter((h) =>
              h.applies(event.id)
            );
            for (const h of applicableHandlers) {
              h.apply(event.id, network);
            }
            break;
          }
          case "data": {
            const applicableHandlers = dataHandlers.filter((h) =>
              h.applies(event.id, event.data)
            );
            for (const h of applicableHandlers) {
              h.apply(event.id, event.data, network);
            }
            break;
          }
        }
      }

      dispatch({ type: "clear-events" });
    }
  }, [state.events, connectHandlers, dataHandlers, network]);

  return network;
}

export const NetworkProvider: React.FC = ({ children }) => {
  const network = useNetworkProvider();
  return <Context.Provider value={network}>{children}</Context.Provider>;
};

export type Data = Record<string, unknown>;

export type DataHandler<T extends Data = Data> = {
  applies: (id: string, data: Data) => data is T;
  apply: (id: string, data: T, network: Network) => void;
};

export type ConnectHandler = {
  applies: (id: string) => boolean;
  apply: (id: string, network: Network) => void;
};

export interface Network {
  // all known peers
  peers: {
    id: string;
    online: boolean;
    username: string | undefined;
  }[];
  // connect to a peer, updates the peers object
  connect(id: string): Promise<Peer.DataConnection>;
  // sets the username of a peer
  setPeerUsername(id: string, name: string | undefined): void;
  // disconnect from a peer, updates the peers object
  disconnect(id: string): void;
  // forget a peer, also disconnecting from it, updates the peers object
  forget(id: string): void;
  // sends data to a peer if it is online
  send<T extends Data>(id: string, data: T): void;
  // sends data to all peers that are currently online
  broadcast(data: Data): void;
  // register and unregister handlers
  on<T extends Data>(event: "data", handler: DataHandler<T>): void;
  on(event: "connect", handler: ConnectHandler): void;
  off<T extends Data>(event: "data", handler: DataHandler<T>): void;
  off(event: "connect", handler: ConnectHandler): void;
}

export default function useNetwork() {
  return useContext(Context);
}
