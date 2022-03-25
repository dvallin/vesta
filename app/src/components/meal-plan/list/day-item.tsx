import { IonLabel, IonListHeader } from "@ionic/react";
import { format } from "date-fns";

export interface DayItemProps
  extends React.ComponentPropsWithRef<typeof IonListHeader> {
  date: number;
}

const DayItem: React.FC<DayItemProps> = ({ date }) => (
  <IonListHeader>
    <IonLabel>{format(date, "EEEE (dd.MM.)")}</IonLabel>
  </IonListHeader>
);

export default DayItem;
