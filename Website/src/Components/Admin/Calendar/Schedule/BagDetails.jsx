import React, { useState } from 'react'
import {
    Menu,
    MenuHandler,
    MenuList,
    MenuItem,
    Button,
    Dialog,
    Card,
    CardBody,
    Typography,
    Input,
    CardFooter,
} from "@material-tailwind/react";
import { EllipsisVerticalIcon } from '@heroicons/react/24/solid';
import { updateBag } from '../../../../redux/actions/bagActions';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';
import PropTypes from 'prop-types';
const BagDetails = ({ bag, from, status, scheduleId }) => {
    const [bagDetails, setBagDetails] = useState(() => ({
        volume: "",
        expressDate: null
    }))
    
    const [id, setId] = useState(null);
    const [open, setOpen] = useState(false);
    const dispatch = useDispatch(); 
    const handleEdit = (bag) => {
        console.log("Edit Bag: ", bag._id)
        setBagDetails({
            volume: bag.volume,
            expressDate: new Date(new Date(bag.expressDate).getTime() - new Date(bag.expressDate).getTimezoneOffset() * 60000).toISOString().slice(0, 16) // Format to YYYY-MM-DDTHH:MM
        })
        setId(bag._id);
        setOpen(true);
        // Implement edit functionality here
    }
    const handleDateChange = (e) => {
        setBagDetails({
            ...bagDetails,
            expressDate: e.target.value
        })
    }
    const handleVolumeChange = (e) => {
        setBagDetails({
            ...bagDetails,
            volume: e.target.value
        })
    }
    const submitUpdate = () => {
      
        const data = {
            volume: bagDetails.volume,
            expressDate: bagDetails.expressDate,
            id: id,
            collectionId: scheduleId
        }
        dispatch(updateBag(data))
            .then(() => {
                location.reload()
                toast.success("Bag Updated", { position: "bottom-right" });
            })
            .catch((error) => {
                toast.error("Failed to update bag", { position: "bottom-right" });
                console.error(error);
            });
        
        setOpen(false);
    }
    return (
        <>
            <div className="relative w-96 p-4 bg-white rounded-lg shadow-md border flex flex-col h-full">
                {from === "RedirectDetails" && status !== "Stored" && <div className="pr-4" style={{ position: 'absolute', right: '0' }}>
                    <Menu>
                        <MenuHandler>
                            <EllipsisVerticalIcon className="h-6 w-6 hover:cursor-pointer text-black hover:bg-gray-600/30 rounded-full" />
                        </MenuHandler>
                        <MenuList className="shadow-lg bg-white text-black border border-gray-400 min-w-max">
                            <MenuItem onClick={() => handleEdit(bag)}>Edit</MenuItem>
                            
                        </MenuList>
                    </Menu>
                </div>}

                <div className="flex items-center justify-center gap-4">
                    <div className="w-full">
                        {/* Title */}
                        <div className="mt-2">
                            <span className="font-parkinsans text-xl break-words whitespace-normal">Date Expressed: </span>
                            <p className="font-parkinsans text-xl break-words whitespace-normal">{new Date(bag.expressDate)
                                .toLocaleString("en-US", {
                                    year: "numeric",
                                    month: "long",
                                    day: "numeric",
                                    hour: "numeric",
                                    minute: "2-digit",
                                    hour12: true, // Ensures AM/PM format
                                })}</p>
                        </div>
                    </div>
                </div>
                <span className="flex items-center w-full my-4">
                    <span className="h-px flex-1 bg-black"></span>
                </span>
                {/* Description */}
                <div className="flex flex-col flex-grow mt-2">

                    <span className="font-parkinsans text-3xl text-secondary font-bold break-words whitespace-normal">{bag.volume} ml</span>
                </div>
            </div>
            <Dialog
                size="xs"
                open={open}
                handler={setOpen}
                className="bg-transparent shadow-none"
            >
                <Card className="mx-auto w-full max-w-[24rem]">

                    <CardBody className="flex flex-col gap-4">
                        <Typography variant="h4" color="blue-gray">
                            Edit bag details
                        </Typography>
                        
                        <div className="w-full">
                            <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                Express date
                            </Typography>
                            <Input
                                type="datetime-local"
                                name="expressDate"
                                onChange={handleDateChange}
                                value={bagDetails.expressDate || ""}
                            />

                        </div>
                        <div className="w-full">
                            <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                Volume
                            </Typography>
                            <Input
                                type="text"
                                name="volume"
                                onChange={handleVolumeChange}
                                value={bagDetails.volume}

                            />

                        </div>


                    </CardBody>
                    <CardFooter className="pt-0 flex items-center justify-between gap-4">
                        <Button variant="gradient" color="deep-orange" onClick={submitUpdate} fullWidth>
                            Update
                        </Button>
                    </CardFooter>

                </Card>
            </Dialog>

        </>
    )
}

BagDetails.propTypes = {
    bag: PropTypes.object.isRequired,
    from: PropTypes.string.isRequired,
    status: PropTypes.string.isRequired,
    scheduleId: PropTypes.string.isRequired
}
export default BagDetails