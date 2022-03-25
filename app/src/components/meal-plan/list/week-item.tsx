import { IonLabel, IonListHeader } from "@ionic/react";
import { format } from "date-fns";

export interface WeekItemProps
  extends React.ComponentPropsWithRef<typeof IonListHeader> {
  date: number;
}

const WeekItem: React.FC<WeekItemProps> = ({ date }) => (
  <IonListHeader color="primary">
    <IonLabel>Week {format(date, "ww")}</IonLabel>
  </IonListHeader>
);

export default WeekItem;
