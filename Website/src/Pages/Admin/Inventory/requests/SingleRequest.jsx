import React, { useState, useEffect } from 'react'
import { Link, useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux'
import { getRequestDetails, updateRequestStatus, updateVolumeRequested } from '../../../../redux/actions/requestActions';
import { Button, ButtonGroup, Card, CardBody, CardFooter, Dialog, DialogBody, Drawer, IconButton, Input, Tab, TabPanel, Tabs, TabsBody, TabsHeader, Textarea, Typography } from '@material-tailwind/react'
import { useFormik } from 'formik'
import * as Yup from 'yup'
import { ArrowLongLeftIcon, XMarkIcon } from '@heroicons/react/24/solid'
import { toast } from 'react-toastify'
import { getFridges } from '../../../../redux/actions/fridgeActions';
import { getInventories, reserveInventory } from '../../../../redux/actions/inventoryActions';
import { getUser } from '../../../../utils/helper';
import placeholder from '../../../../assets/image/placeholder-image.webp'
import { resetUpdate } from '../../../../redux/slices/requestSlice';
import { useBreadcrumb } from '../../../../Components/Breadcrumb/BreadcrumbContext';
import InventoryCardComponent from '../../../../Components/Admin/Inventory/InventoryCardComponent';

const SingleRequest = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();
    const { requestDetails, isUpdated } = useSelector(state => state.requests)
    const { fridges } = useSelector(state => state.fridges)
    const { id } = useParams();
    const navigate = useNavigate();
    const [ebm, setEbm] = useState([])
    useEffect(() => {
        // console.log("id: ", id)
        dispatch(getRequestDetails(id));
        dispatch(getFridges());
        dispatch(getInventories())
    }, [id])
    const { inventory } = useSelector(state => state.inventories)
    const [open, setOpen] = useState(false);
    const [selectedImage, setSelectedImage] = useState(null);
    const [openUpdateVolume, setOpenUpdateVolume] = useState(false);
    const [openFridge, setOpenFridge] = useState(false);
    const [comment, setComment] = useState('');
    const [openComment, setOpenComment] = useState(false);
    const handleOpenFridge = () => {
        setOpenFridge(!openFridge);
    }
    const handleUpdateVolume = () => {
        setOpenUpdateVolume(!openUpdateVolume);
    }
    const handleOpen = (imgUrl) => {
        setSelectedImage(imgUrl);
        setOpen(true);
    };
    const formik = useFormik({
        initialValues: {
            volume: "",
            days: ""

        },
        validationSchema: Yup.object({
            volume: Yup.number().required('Volume is required').positive('Volume must be a positive number').integer('Volume must be an integer'),
            days: Yup.number().required('Days is required').positive('Days must be a positive number').integer('Days must be an integer')
        }),
        onSubmit: (values) => {
            console.log("values: ", values)
            const data = {
                id: requestDetails._id,
                volume: values.volume,
                days: values.days
            }
            dispatch(updateVolumeRequested(data)).then(() => {
                handleUpdateVolume();
                toast.success("Volume Updated", { position: "bottom-right" })
            }).catch((err) => {
                console.log("error: ", err)
                toast.error("Error updating volume", { position: "bottom-right" })
            })
        }
    })


    useEffect(() => {
        if (requestDetails) {
            formik.setFieldValue("volume", requestDetails.volumeRequested?.volume?.toString() || '')
            formik.setFieldValue("days", requestDetails.volumeRequested?.days?.toString() || '')
        }
    }, [requestDetails])
    const pasteurizedFridges = fridges ? fridges.filter((f) => f.fridgeType === 'Pasteurized') : [];
    const [selectedOption, setSelectedOption] = useState('');
    const [selectedInventory, setSelectedInventory] = useState('');
    const [inventoryDetails, setInventoryDetails] = useState({});
    const [selectedVolume, setSelectedVolume] = useState(0);
    const [volume, setVolume] = useState(0);
    const [data, setData] = useState(() => ({
        start: "",
        end: ""
    }))
    const handleStart = (e) => {
        setFormError((prev) => ({
            ...prev,
            start: { status: false, message: "" }
        }))
        const selectedBottle = inventoryDetails.pasteurizedDetails.bottles.filter((b) => b.bottleNumber >= e.target.value && b.bottleNumber <= data.end);
        setVolume(Number(selectedBottle.length * inventoryDetails.pasteurizedDetails.bottleType))
        setData((prev) => ({
            ...prev,
            start: e.target.value
        }))

    }
    const handleEnd = (e) => {
        setFormError((prev) => ({
            ...prev,
            end: { status: false, message: "" }
        }))
        const selectedBottle = inventoryDetails.pasteurizedDetails.bottles.filter((b) => b.bottleNumber >= data.start && b.bottleNumber <= e.target.value);
        setVolume(Number(selectedBottle.length * inventoryDetails.pasteurizedDetails.bottleType))
        setData((prev) => ({
            ...prev,
            end: e.target.value
        }))
    }

    const [formError, setFormError] = useState(() => ({
        fridge: { status: false, message: "" },
        start: { status: false, message: "" },
        end: { status: false, message: "" },
        inventory: { status: false, message: "" },
        addEbm: { status: false, message: "" },
        comment: { status: false, message: "" }
    }));
    const handleSubmit = () => {
        
        let startLimit = 0;
        let endLimit = 0;

        if (Object.keys(inventoryDetails).length > 0) {
            const availableBottles = inventoryDetails.pasteurizedDetails.bottles.filter((b) => b.status === 'Available')
            console.log("available: ", availableBottles);
            startLimit = Number(availableBottles[0].bottleNumber)
            endLimit = Number(availableBottles[availableBottles.length - 1].bottleNumber)
        }
        if (!selectedOption) {
            setFormError((prev) => ({
                ...prev,
                fridge: { status: true, message: "Please select a fridge" },
                inventory: { status: true, message: "Please select a fridge first" }
            }))
        }
        if (!selectedInventory) {
            setFormError((prev) => ({
                ...prev,
                inventory: { status: true, message: "Please select a batch" }
            }))
        }
        if (!data.start) {
            setFormError((prev) => ({
                ...prev,
                start: { status: true, message: "Please enter a starting bottle number" }
            }))
        }
        if (!data.end) {
            setFormError((prev) => ({
                ...prev,
                end: { status: true, message: "Please enter an ending bottle number" }
            }))
        }
        if (data.start < startLimit) {
            setFormError((prev) => ({
                ...prev,
                start: { status: true, message: `Starting bottle number should be greater than ${startLimit}` }
            }))
        }
        if (data.start > endLimit) {
            setFormError((prev) => ({
                ...prev,
                start: { status: true, message: `Starting bottle number should be less than ${endLimit}` }
            }))
        }
        if (data.end < startLimit) {
            setFormError((prev) => ({
                ...prev,
                end: { status: true, message: `Ending bottle number should be greater than ${startLimit}` }
            }))
        }
        if (data.end > endLimit) {
            setFormError((prev) => ({
                ...prev,
                end: { status: true, message: `Ending bottle number should be less than ${endLimit}` }
            }))
        }
        const ebmDetails = {
            invId: inventoryDetails._id,
            bottleType: inventoryDetails.pasteurizedDetails.bottleType,
            batch: inventoryDetails.pasteurizedDetails.batch,
            pool: inventoryDetails.pasteurizedDetails.pool,
            bottle: {
                start: data.start,
                end: data.end
            },
            volDischarge: Number(volume),
        }
        const updatedEbm = [...ebm, ebmDetails];
        setEbm(updatedEbm);
        const data2 = {
            id: requestDetails._id,
            ebmData: updatedEbm,
        }
        console.log("Data: ", data2);
        dispatch(reserveInventory(data2)).then(() => {
            toast.success("Bottles Reserved", { position: 'bottom-right' });
            handleOpenFridge();
            navigate('/dashboard/requests')
        }).catch((err) => console.log(err));

        setSelectedInventory('')
        setInventoryDetails({})
        setSelectedOption('')
        setData(() => ({
            start: "",
            end: ""
        }))
        setVolume(0)
        setSelectedVolume(0)
        setFormError(() => ({
            fridge: { status: false, message: "" },
            start: { status: false, message: "" },
            end: { status: false, message: "" },
            inventory: { status: false, message: "" },
            addEbm: { status: false, message: "" }
        }))
    }
    const handleChangeInventory = (e) => {
        setFormError((prev) => ({
            ...prev,
            inventory: { status: false, message: "" },
            start: { status: false, message: "" },
            end: { status: false, message: "" },
            addEbm: { status: false, message: "" }
        }))
        setData(() => ({
            start: "",
            end: ""
        }))
        setVolume(0)
        const details = filteredInventories.find((inv) => inv._id === e.target.value)
        const availableBottles = details.pasteurizedDetails.bottles.filter((b) => b.status === 'Available')
        const requiredVolume = requestDetails.volumeRequested.volume * requestDetails.volumeRequested.days
        const remainingVolume = requiredVolume - selectedVolume;
        if (remainingVolume > 0) {
            const bottlesNeeded = Math.ceil(remainingVolume / details.pasteurizedDetails.bottleType);
            const bottlesToUse = availableBottles.slice(0, bottlesNeeded);
            const newStart = bottlesToUse[0].bottleNumber;
            const newEnd = bottlesToUse[bottlesToUse.length - 1].bottleNumber;
            const newVolume = bottlesToUse.length * details.pasteurizedDetails.bottleType;
            setData(() => ({
                start: newStart,
                end: newEnd
            }))
            setVolume(newVolume);
        }

        setInventoryDetails(details)
        setSelectedInventory(e.target.value)
    }
    const handleChange = (e) => {
        setFormError((prev) => ({
            ...prev,
            fridge: { status: false, message: "" }
        }))
        setSelectedOption(e.target.value)
    }
    const filteredInventories = inventory?.filter(
        (inv) =>
            inv.fridge &&
            inv.fridge._id === selectedOption &&
            inv.status !== "Unavailable"
    );
    const addEbm = () => {

        if (!selectedInventory) {
            setFormError((prev) => ({
                ...prev,
                addEbm: { status: true, message: "Please select a batch" }
            }))
            return;
        }
        const ebmDetails = {
            invId: inventoryDetails._id,
            bottleType: inventoryDetails.pasteurizedDetails.bottleType,
            batch: inventoryDetails.pasteurizedDetails.batch,
            pool: inventoryDetails.pasteurizedDetails.pool,
            bottle: {
                start: data.start,
                end: data.end
            },
            volDischarge: Number(volume),
        }
        setEbm((prev) => [...prev, ebmDetails])
        setSelectedInventory('')
        setData(() => ({
            start: "",
            end: ""
        }))
        console.log("ebmDetails: ", ebmDetails)
        setSelectedVolume((prev) => prev + Number(volume))
        setVolume(0);
        setInventoryDetails({})
        setSelectedInventory('');
    }
    const handleComment = () => {
        setOpenComment(!openComment);
    }
    const denyRequest = () => {
        if (!comment) {
            setFormError((prev) => ({ ...prev, comment: { status: true, message: "Please enter a comment" } }))
            return;
        }
        const data = {
            id: requestDetails._id,
            status: 'Canceled',
            userID: getUser()?._id,
            comment: comment
        }
        dispatch(updateRequestStatus(data)).then(() => {
            handleComment();
            toast.success("Request Denied", { position: "bottom-right" });
            dispatch(getRequestDetails(id))
        })
    }

    useEffect(() => {
        if (isUpdated) {
            toast.error("Request Denied");
            dispatch(resetUpdate())
        }
    }, [isUpdated])
    useEffect(() => {
        setBreadcrumb([
            { "name": "Dashboard", "path": "/dashboard" },
            { "name": "Requests", "path": "/dashboard/requests" },
            { "name": `Request Details` }
        ])
    }, [])
    // Define this at the top or in a config file
    const statusColors = {
        Pending: 'rgb(255, 193, 7)',
        Approved: 'rgb(229, 55, 119)',
        Completed: 'rgb(76, 175, 80)',
        default: 'rgb(255, 51, 85)', // fallback for other statuses
    };

    // Determine border color based on request status
    const borderColor = statusColors[requestDetails?.status] || statusColors.default;
    return (
        <div className="p-8">
            <div className="flex flex-col gap-4 justify-between items-center">
                <div className="w-full">
                    <Link to={`/dashboard/requests`}>
                        <div className="h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                            <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                        </div>
                    </Link>
                </div>

                <div className="font-parkinsans text-2xl text-center">{requestDetails.patient?.patientType} Request Details</div>
                <Tabs value="requestDetails" className="w-full">
                    <TabsHeader>
                        <Tab value="requestDetails" className=" text-secondary">
                            Request Details
                        </Tab>
                        <Tab value="attachments" className=" text-secondary">
                            Attachments
                        </Tab>
                    </TabsHeader>
                    <TabsBody animate={{ initial: { visibility: 'visible' }, mount: { visibility: 'visible' }, unmount: { visibility: 'hidden' } }} className="h-full">
                        <TabPanel value="requestDetails" className="h-full">
                            <Card className='w-full border-l-8 border-accent-green' style={{ boderLeftWidth: '8px', borderColor }}>
                                <CardBody>
                                    <div className="flex flex-col gap-4">
                                        <div className="flex items-center justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Patient Name</span>
                                            <span className="font-parkinsans text-lg">{requestDetails.patient?.name}</span>
                                        </div>
                                        <div className="flex items-center justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Department</span>
                                            <span className="font-parkinsans text-lg">{requestDetails.department ? requestDetails.department : '(Outpatient)'}</span>
                                        </div>
                                        <div className="flex items-center justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Hospital</span>
                                            <span className="font-parkinsans text-lg">{requestDetails.hospital}</span>
                                        </div>
                                        <div className="flex items-center justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Doctor</span>
                                            <span className="font-parkinsans text-lg">{requestDetails.doctor}</span>
                                        </div>
                                        <div className="flex items-center justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Requested by</span>
                                            <span className="font-parkinsans text-lg">{`${requestDetails.requestedBy?.name?.first} ${requestDetails.requestedBy?.name?.last}`}</span>
                                        </div>
                                        <span className="flex items-center my-4">
                                            <span className="h-px flex-1 bg-gray-500"></span>
                                        </span>
                                        <div className="flex flex-col items-start justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Diagnosis</span>
                                            <span className="font-parkinsans text-lg">{requestDetails.diagnosis}</span>
                                        </div>
                                        <div className="flex flex-col items-start justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Reason</span>
                                            <span className="font-parkinsans text-lg text-justify">{requestDetails.reason}</span>
                                        </div>
                                        <div className="flex flex-col items-start justify-between">
                                            <span className="font-parkinsans text-lg font-bold">Volume Requested</span>
                                            <span className="font-parkinsans text-3xl text-secondary font-bold">{requestDetails.volumeRequested?.volume} ml / {requestDetails.volumeRequested?.days} days</span>
                                        </div>
                                        {requestDetails.status === 'Canceled' && (
                                            <div className="flex flex-col items-start justify-between">
                                                <span className="font-parkinsans text-lg font-bold">Comment</span>{requestDetails.comment ? requestDetails.comment : ''}
                                            </div>
                                        )}

                                    </div>
                                </CardBody>
                                <CardFooter>
                                    {getUser()?.role === "Admin" || getUser()?.role === "SuperAdmin" && requestDetails.status === 'Pending' ? <div className="w-full flex items-center justify-end gap-4">
                                        <ButtonGroup ripple={true} color="green">
                                            <Button onClick={handleUpdateVolume} color="green">Adjust Volume</Button>
                                            <Button color="green" onClick={handleOpenFridge}>Approve</Button>
                                        </ButtonGroup>
                                        <Button color="red" onClick={handleComment}>Deny</Button>
                                    </div> : null}


                                </CardFooter>
                            </Card>

                        </TabPanel>
                        <TabPanel value="attachments" className="h-full">
                            <div className="flex items-center justify-center md:justify-start flex-wrap gap-4">
                                {requestDetails.images?.map((image) => (
                                    <Card
                                        key={image.url}
                                        className="w-max cursor-pointer overflow-hidden transition-opacity hover:opacity-90"
                                        onClick={() => handleOpen(image.url)}
                                    >
                                        <img src={image.url} alt="prescription" className="w-72 h-52 object-cover" />
                                    </Card>
                                ))}
                            </div>

                        </TabPanel>
                    </TabsBody>
                </Tabs>
                <Dialog open={openComment} handler={handleComment} size="sm" className="p-4">

                    <div className="w-full">
                        <Typography variant="h4" color="blue-gray" className="font-sofia mb-2 font-medium">
                            Enter Comment
                        </Typography>
                        <Textarea
                            label="Comment"
                            name="comment"
                            onChange={(e) => { setFormError((prev) => ({ ...prev, comment: { status: false, message: "" } })); setComment(e.target.value) }}
                            value={comment}
                        />
                        {formError?.comment?.status && <Typography color="red" variant="small">
                            {formError?.comment?.message}
                        </Typography>}
                    </div>

                    <div className="flex items-start justify-end pt-4">
                        <Button type="submit" color="pink" onClick={denyRequest}>
                            Send Comment
                        </Button>
                    </div>


                </Dialog>
                <Dialog open={openUpdateVolume} handler={handleUpdateVolume} size="sm" className="p-4">
                    <form onSubmit={formik.handleSubmit} className="space-y-4">
                        <div className="w-full">
                            <Typography variant="h4" color="blue-gray" className="font-sofia mb-2 font-medium">
                                Enter New Volume
                            </Typography>
                            <Input
                                type="number"
                                label="Volume"
                                name="volume"
                                onChange={formik.handleChange}
                                onBlur={formik.handleBlur}
                                value={formik.values.volume}
                                error={formik.touched.volume && Boolean(formik.errors.volume)}
                            />
                            {formik.touched.volume && formik.errors.volume && (
                                <Typography color="red" variant="small">
                                    {formik.errors.volume}
                                </Typography>
                            )}
                        </div>
                        <div className="w-full">
                            <Typography variant="h4" color="blue-gray" className="font-sofia mb-2 font-medium">
                                Enter New Days
                            </Typography>
                            <Input
                                type="number"
                                label="Days"
                                name="days"
                                onChange={formik.handleChange}
                                onBlur={formik.handleBlur}
                                value={formik.values.days}
                                error={formik.touched.days && Boolean(formik.errors.days)}
                            />
                            {formik.touched.days && formik.errors.days && (
                                <Typography color="red" variant="small">
                                    {formik.errors.days}
                                </Typography>
                            )}
                        </div>
                        <div className="flex items-start justify-end pt-4">
                            <Button type="submit" color="pink">
                                Update
                            </Button>
                        </div>

                    </form>
                </Dialog>
                <Drawer open={openFridge} onClose={handleOpenFridge} dismiss={{ outsidePress: false }} size={500} className="p-4">
                    <div className="mb-4">
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
                            onClick={handleOpenFridge}
                        >
                            <XMarkIcon className="h-4 w-4 stroke-2" />
                        </IconButton>
                    </div>
                    <div className="overflow-y-auto h-[calc(100vh-15rem)] pr-2">
                        <div className="flex items-stretch gap-4 max-w-screen-2xl overflow-x-auto whitespace-nowrap">
                            {pasteurizedFridges?.length > 0 && pasteurizedFridges.map((fridge) => (
                                <div key={fridge._id} className="w-full">
                                    <input
                                        type="radio"
                                        id={`${fridge._id}_${fridge.name}`}
                                        name={`${fridge._id}_${fridge.name}`}
                                        value={fridge._id}
                                        className="peer hidden"
                                        required
                                        checked={selectedOption === fridge._id}
                                        onChange={handleChange}
                                    />
                                    <label
                                        htmlFor={`${fridge._id}_${fridge.name}`}
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

                            {formError?.fridge?.status && <Typography color="red" variant="small">
                                {formError?.fridge?.message}
                            </Typography>}
                        </div>
                        <span className="flex items-center my-4">
                            <span className="h-px flex-1 bg-gray-500"></span>
                        </span>

                        <div className="flex items-stretch gap-4 max-w-screen-2xl overflow-x-auto whitespace-nowrap">
                            {filteredInventories?.length > 0 ? (
                                filteredInventories.map((inventory) => (
                                    <InventoryCardComponent
                                        key={inventory._id}
                                        inventory={inventory}
                                        selectedInventory={selectedInventory}
                                        handleChangeInventory={handleChangeInventory}
                                        ebm={ebm}
                                    />
                                ))
                            ) : selectedOption ? (
                                <Typography color="red" variant="small">
                                    Fridge is empty. Choose another one.
                                </Typography>
                            ) : (
                                <Typography color="blue-gray" variant="small">
                                    No fridge selected
                                </Typography>
                            )}

                        </div>

                        {formError?.inventory?.status && <Typography color="red" variant="small">
                            {formError?.inventory?.message}
                        </Typography>}
                        <div className="space-y-4 mt-8">
                            <div className="w-full">
                                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                    Enter Starting Bottle Number
                                </Typography>
                                <Input
                                    type="number"
                                    label="Bottle Number"
                                    name="start"
                                    value={data.start}
                                    onChange={handleStart}
                                />
                                {formError.start?.status && (
                                    <Typography color="red" variant="small">
                                        {formError.start?.message}
                                    </Typography>
                                )}
                            </div>
                            <div className="w-full">
                                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                    Enter Ending Bottle Number
                                </Typography>
                                <Input
                                    type="number"
                                    label="Bottle Number"
                                    name="end"
                                    value={data.end}
                                    onChange={handleEnd}
                                />
                                {formError.end?.status && (
                                    <Typography color="red" variant="small">
                                        {formError.end?.message}
                                    </Typography>
                                )}
                            </div>
                        </div>
                        <div className="flex items-center justify-start gap-4 pt-4 mb-4">
                            <Button color="pink" variant="gradient" size="sm" onClick={addEbm} disabled={volume + selectedVolume >= (requestDetails?.volumeRequested?.volume * requestDetails?.volumeRequested?.days)}>
                                Select More
                            </Button>
                            {formError.addEbm?.status && (
                                <Typography color="red" variant="small">
                                    {formError.addEbm?.message}
                                </Typography>
                            )}
                        </div>


                    </div>
                    <div className="flex flex-col items-start justify-between pt-4">
                        <div className="flex gap-8 w-full mb-4">
                            <div>
                                <Typography variant="paragraph" color="blue-gray" className="font-sofia font-medium">
                                    Requested Volume:
                                </Typography>
                                <Typography variant="h5" color="pink" className="font-sofia font-medium">
                                    {requestDetails?.volumeRequested?.volume} ml / {requestDetails?.volumeRequested?.days} days ({requestDetails?.volumeRequested?.volume * requestDetails?.volumeRequested?.days} ml)
                                </Typography>
                            </div>
                            <div>
                                <Typography variant="paragraph" color="blue-gray" className="font-sofia font-medium">
                                    Selected Volume:
                                </Typography>
                                <Typography variant="h5" color="pink" className="font-sofia font-medium">
                                    <span className={selectedVolume + volume >= (requestDetails?.volumeRequested?.volume * requestDetails?.volumeRequested?.days) ? "text-success" : ""} >{selectedVolume + volume} ml </span>
                                </Typography>
                            </div>

                        </div>
                        <Button color="pink" size="md" fullWidth onClick={handleSubmit}>
                            Reserve
                        </Button>
                    </div>
                </Drawer>

                <Dialog size="xl" open={open} handler={() => setOpen(false)}>
                    <DialogBody className="h-[calc(100vh-8rem)] overflow-y-auto">
                        {selectedImage ? (
                            <img src={selectedImage} alt="prescription" className="w-full h-[48rem] object-contain" />
                        ) : <img src={placeholder} alt="prescription" className="w-full h-[48rem] object-contain" />}
                    </DialogBody>
                </Dialog>

            </div >
        </div>
    )
}

export default SingleRequest