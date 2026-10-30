import { Typography } from "@material-tailwind/react";
import { formatDate } from "../../../utils/helper";
import PropTypes from "prop-types";

const InventoryCardComponent = ({ inventory, selectedInventory, handleChangeInventory, ebm }) => {
  const isDisabled = ebm.some((inv) => inv.invId === inventory._id);
  const bottles = inventory.pasteurizedDetails.bottles.filter((b) => b.status === 'Available');

  return (
    <div key={inventory._id} className="min-w-max">
      <input
        type="radio"
        id={inventory.pasteurizedDetails.batch}
        name="inventory-selection"
        value={inventory._id}
        className="peer hidden"
        required
        checked={selectedInventory === inventory._id}
        onChange={handleChangeInventory}
        disabled={isDisabled}
      />
      <label
        htmlFor={inventory.pasteurizedDetails.batch}
        className={`block w-full cursor-pointer rounded-lg border border-gray-300 p-4 ${isDisabled ? 'text-gray-500' : 'text-gray-900'} ring-1 ring-transparent peer-checked:border-gray-900 peer-checked:ring-gray-900`}
      >
        <div className="relative w-96 bg-white rounded-lg flex flex-col h-full">
          <div className="flex items-center justify-between">
            <Typography variant="lead" className="font-varela font-bold">
              Batch #: {inventory.pasteurizedDetails.batch}
            </Typography>
            <Typography
              variant="small"
              className={`${isDisabled ? 'text-gray-500' : 'text-secondary'} font-varela font-bold`}
            >
              {inventory.pasteurizedDetails.bottleType} ml
            </Typography>
          </div>
          <Typography variant="lead" className="font-varela font-bold">
            Pool #: {inventory.pasteurizedDetails.pool}
          </Typography>
          <Typography variant="lead" className="font-varela font-bold">
            Bottle #: {`${bottles[0].bottleNumber} - ${bottles[bottles.length - 1].bottleNumber}`}
          </Typography>
          <Typography variant="small" className="font-varela">
            Expiry Date: {formatDate(inventory.pasteurizedDetails.expiration)}
          </Typography>
          <Typography variant="small" className="font-varela">
            Pasteurization Date: {formatDate(inventory.pasteurizedDetails.pasteurizationDate)}
          </Typography>
        </div>
      </label>
    </div>
  );
};
InventoryCardComponent.propTypes = {
    inventory: PropTypes.object.isRequired,
    selectedInventory: PropTypes.string.isRequired,
    handleChangeInventory: PropTypes.func.isRequired,
    ebm: PropTypes.array.isRequired,
}
export default InventoryCardComponent;