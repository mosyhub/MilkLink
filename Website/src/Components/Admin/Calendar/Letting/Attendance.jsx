import React, { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { Link, useLocation, useParams, useNavigate} from 'react-router-dom'
import { finalizeSession, getLettingDetails } from '../../../../redux/actions/lettingActions';
import AttendanceTable from './AttendanceTable';
import { Button, ButtonGroup, Dialog, DialogBody, DialogFooter, DialogHeader, IconButton, Typography } from '@material-tailwind/react';
import { ArrowLongLeftIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { recordPublicRecord } from '../../../../redux/actions/collectionActions';
import { toast } from 'react-toastify';
import { getUserDetails } from '../../../../redux/actions/userActions';
import { getFridges } from '../../../../redux/actions/fridgeActions';
import { addInventory } from '../../../../redux/actions/inventoryActions';
import { SquareCheck } from 'lucide-react';
import { useBreadcrumb } from '../../../Breadcrumb/BreadcrumbContext';

const Attendance = () => {
  const { setBreadcrumb } = useBreadcrumb();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { id } = useParams();
  const location = useLocation();
  const { lettingDetails } = useSelector((state) => state.lettings);
  const { fridges } = useSelector((state) => state.fridges);
  const { userDetails } = useSelector((state) => state.users);
  const from = location.state?.from;
  const collectionId = location.state?.collectionId;
  const status = location.state?.status
  const eventStatus = location.state?.eventStatus;
  const [open, setOpen] = useState(false);
  const [selectedOption, setSelectedOption] = useState('');
  const [openSubmit, setOpenSubmit] = useState(false)

  const handleOpen = () => setOpen(!open);
  const handleOpenSubmit = () => setOpenSubmit(!openSubmit);
  const handleChange = (e) => {
    setSelectedOption(e.target.value)
  }
  const [refresh, setRefresh] = useState(false);
  useEffect(() => {
    if (eventStatus === 'Done') {
      setBreadcrumb([
        { name: "Dashboard", path: "/dashboard" },
        { name: "Event Schedules", path: "/dashboard/events" },
        { name: "History", path: "/dashboard/event/history" },
        { name: "Attendance" }
      ])
    }
    else {
      setBreadcrumb([
        { name: "Dashboard", path: "/dashboard" },
        { name: "Event Schedules", path: "/dashboard/events" },
        { name: "Attendance" }
      ])
    }

  }, [eventStatus])
  useEffect(() => {
    console.log('dispatching getlettingdetails')
    dispatch(getLettingDetails(id));
    dispatch(getUserDetails());
    dispatch(getFridges());

  }, [dispatch, id])

  const unpasteurizedFridges = fridges ? fridges.filter((f) => f.fridgeType === 'Unpasteurized') : [];
  const handleSubmit = () => {
    if (!userDetails || !id) {
      toast.error("Error: Missing required fields", { position: "bottom-right" });
      return;
    }

    const finalizeData = {
      adminId: userDetails._id,
      lettingId: id,
    };

    dispatch(finalizeSession(finalizeData))
      .then(() => {
        dispatch(recordPublicRecord({ lettingId: id })).then(() => {
          toast.success(`Milk Letting event has been finalized`, { position: "bottom-right" });
          navigate("/dashboard/events");
        });
      })
      .catch((error) => {
        toast.error("Failed to add fridge. Please try again.", { position: "bottom-right" });
        console.error(error);
      });
    handleOpenSubmit();
  };
  const submitFridge = () => {
    if (!selectedOption) {
      toast.error("Please select a fridge", { position: "bottom-right" });
      setOpen(false);
      return;
    }
    console.log('selected option: ', selectedOption)
    const data = {
      fridgeId: selectedOption,
      unpasteurizedDetails: { collectionId },
      userId: userDetails._id
    }
    dispatch(addInventory(data)).then(() => {
      toast.success("Collection stored successfully", { position: "bottom-right" });
      setOpen(false);
    }).catch((error) => {
      toast.error("Failed to store collection. Please try again.", { position: "bottom-right" });
      console.error(error);
      setOpen(false)
    })

  }
  useEffect(() => {
    if (refresh) {
      dispatch(getLettingDetails(id))
      setRefresh(false);
    }
  }, [refresh])
  useEffect(() => {
    // Load the Tally embed script
    const script = document.createElement("script");
    script.src = "https://tally.so/widgets/embed.js";
    script.async = true;
    document.body.appendChild(script);

    // Cleanup the script when the component is unmounted
    return () => {
      document.body.removeChild(script);
    };
  }, [])


  return (
    <>
      <div className="flex flex-col items-center justify-center w-full gap-4 p-4 h-full">
        <div className="flex w-full items-center justify-between gap-4">

          {lettingDetails && lettingDetails.status !== 'Done' ? (<div className="flex flex-col w-full">

            <div className="flex items-center gap-4 justify-between w-full">
              <Typography variant="h2" className="w-max flex items-baseline gap-2">Total Volume: {lettingDetails.totalVolume} ml </Typography>
              <div className='flex gap-4'>

                <ButtonGroup ripple={true}>
                  <Button data-tally-open="wbv1XZ" data-tally-emoji-text="👋" data-tally-emoji-animation="wave" className="bg-secondary" size="sm">
                    Create New Donor
                  </Button>
                  <Button className="bg-secondary" size="sm" onClick={() => navigate(`/dashboard/events/attendance/donations/${id}`)}>
                    Create New Attendance
                  </Button>
                </ButtonGroup>
                <Button size="sm" color="green" onClick={handleOpenSubmit}>
                  Finalize Attendance
                </Button>

              </div>
            </div>

          </div>) : <> {from === "RedirectDetails" ? <Link to={`/dashboard/collections`}>
            <div className="h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
              <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
            </div>
          </Link> : <Link to={`/dashboard/event/history`}>
            <div className="h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
              <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
            </div>
          </Link>}

            <div className="flex justify-center items-center gap-4">
              <Typography variant="h2">Total volume: {lettingDetails.totalVolume} ml</Typography>
              {from && status && from === "RedirectDetails" && status !== "Stored" && <SquareCheck onClick={handleOpen} className="h-10 w-10 font-semibold hover:text-green-500 hover:cursor-pointer" />}
            </div>
          </>}

        </div>

        {lettingDetails && <AttendanceTable setRefresh={setRefresh} attendance={lettingDetails.attendance} from={from} status={status} lettingId={lettingDetails._id} />}

      </div>
      <Dialog size="sm" open={open} handler={handleOpen} className="p-4" dismiss={{ outsidePress: false }}>
        <DialogHeader className="relative m-0 block">
          <Typography variant="h4" color="blue-gray">
            Choose Refrigerator
          </Typography>
          <Typography className="mt-1 font-normal text-gray-600">
            Please select the fridge you would like to store the milk in.
          </Typography>
          <IconButton
            size="sm"
            variant="text"
            className="!absolute right-3.5 top-3.5"
            onClick={handleOpen}
          >
            <XMarkIcon className="h-4 w-4 stroke-2" />
          </IconButton>
        </DialogHeader>
        <DialogBody>
          <div className="space-y-4">

            {unpasteurizedFridges?.length > 0 && unpasteurizedFridges.map((fridge) => (
              <div key={fridge._id}>
                <input
                  type="radio"
                  id={`${fridge.name}_${fridge._id}`}
                  name={fridge.name}
                  value={fridge._id}
                  className="peer hidden"
                  required
                  checked={selectedOption === fridge._id}
                  onChange={handleChange}
                />
                <label
                  htmlFor={`${fridge.name}_${fridge._id}`}
                  className="block w-full cursor-pointer rounded-lg border border-gray-300 p-4 text-gray-900 ring-1 ring-transparent peer-checked:border-gray-900 peer-checked:ring-gray-900"
                >
                  <div className="block">
                    <Typography className="font-semibold">
                      {fridge.name}
                    </Typography>
                    <Typography className="font-normal text-gray-600">
                      {fridge.fridgeType}
                    </Typography>
                  </div>
                </label>
              </div>
            ))}


          </div>
        </DialogBody>
        <DialogFooter>
          <Button className="ml-auto" onClick={submitFridge}>
            Select
          </Button>
        </DialogFooter>
      </Dialog>
      <Dialog size="md" open={openSubmit} handler={handleOpenSubmit} className="p-4">
        <DialogHeader>
          <Typography variant="h5" color="blue-gray" className="text-center w-full">
            Finalize Milk Letting Attendance?
          </Typography>
        </DialogHeader>
        <DialogBody divider className="grid place-items-center gap-2">
          <Typography variant="h5" color="blue-gray">Total Collected Volume:</Typography>
          <Typography color="pink" className="font-sofia" variant="h2">
            {lettingDetails.totalVolume} ml
          </Typography>
          <Typography className="text-center font-normal flex flex-col">
            <span className="text-gray-700">
              A total of <span className="text-secondary font-bold text-lg">{lettingDetails && lettingDetails.attendance?.length} attendance records</span> have been collected for this letting session.
            </span>
            <span className="text-gray-700">Please review the details before finalizing the attendance.</span>
          </Typography>
        </DialogBody>
        <DialogFooter className="space-x-2">
          <Button variant="gradient" color="pink" onClick={handleSubmit}>
            Finalize
          </Button>
        </DialogFooter>
      </Dialog>
    </>
  )
}

export default Attendance