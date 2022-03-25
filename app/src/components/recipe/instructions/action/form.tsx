import { IonItem } from "@ionic/react";
import { formatDuration, parseDuration } from "../../../../model/duration";
import FormattedInput from "../../../form/formatted-input";
import Select from "../../../form/select";

export interface InstructionActionFormProps {
  index: number;
}

const InstructionActionForm: React.FC<InstructionActionFormProps> = ({
  index,
}) => {
  const name = `instructions.${index}.action` as const;
  return (
    <>
      <IonItem lines="none">
        <Select
          name={`${name}.type`}
          options={[
            { value: "step", label: "Step" },
            { value: "preparation", label: "Preparation" },
          ]}
        />
      </IonItem>
      <IonItem lines="none">
        <FormattedInput
          name={`${name}.duration`}
          label="Duration"
          parse={parseDuration}
          format={formatDuration}
        />
      </IonItem>
    </>
  );
};

export default InstructionActionForm;
