import React, { useState, useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { Link, useLocation, useParams, useNavigate } from 'react-router-dom'
import { getSingleSchedule, updateSchedule } from '../../../../redux/actions/scheduleActions'
import { Button, Card, CardBody, CardFooter, Dialog, DialogBody, DialogFooter, DialogHeader, IconButton, Input, Option, Select, Typography } from '@material-tailwind/react'
import { useFormik } from 'formik'
import * as Yup from 'yup'
import BagDetails from './BagDetails'
import { resetSuccess } from '../../../../redux/slices/scheduleSlice'
import { getAllUsers, getUserDetails } from '../../../../redux/actions/userActions'
import { recordPrivateRecord } from '../../../../redux/actions/collectionActions'
import { ArrowLongLeftIcon, XMarkIcon } from '@heroicons/react/24/solid'
import { getFridges } from '../../../../redux/actions/fridgeActions'
import { addInventory } from '../../../../redux/actions/inventoryActions'
import { toast } from 'react-toastify'
import { useBreadcrumb } from '../../../Breadcrumb/BreadcrumbContext'
import { sendNotifications } from '../../../../redux/actions/notifActions'
const PickUpDetails = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();
    const navigate = useNavigate();
    const location = useLocation();
    const { id } = useParams();
    const from = location.state?.from;
    const status = location.state?.status;
    const { fridges } = useSelector((state) => state.fridges);
    const { schedule, success } = useSelector(state => state.schedules);
    const { users, userDetails } = useSelector(state => state.users);
    const [open, setOpen] = useState(false);
    const [complete, setComplete] = useState(false);
    const [selectedOption, setSelectedOption] = useState('');
    const [openFridge, setOpenFridge] = useState(false);
    const collectionId = location.state?.collectionId;
    const handleOpenFridge = () => setOpenFridge(!openFridge);
    const handleChange = (e) => {
        setSelectedOption(e.target.value)
    }
    const validationSchema = Yup.object({
        newDate: Yup.date().required("New date is required"),
    });
    const validationSchema2 = Yup.object({
        admin: Yup.string().required("Admin is required"),
    });
    const handleApprove = () => {
        const data = {
            id,
            status: 'Approved'
        }

        dispatch(updateSchedule(data)).then(() => {
            const notifData = {
                role: "User",
                title: "Scheduled request update",
                body: `Your scheduled request is approved.`,
            };
            dispatch(sendNotifications(notifData)).catch((error) => {
                console.error("Error sending notification:", error);
                toast.error("Error in sending notification");
            });
            toast.success("Notified donor successfully");
        }).catch((error) => {
            console.error("Error adding request:", error);
            toast.error("Failed to add request.");
        });
    }

    const formik = useFormik({
        initialValues: {
            newDate: "",
        },
        validationSchema,
        onSubmit: (values) => {
            const data = {
                id,
                dates: values.newDate,
                status: 'Approved'
            }
            dispatch(updateSchedule(data))
            handleOpen();
        },
    });
    const formik2 = useFormik({
        initialValues: {
            admin: "",
        },
        validationSchema2,
        onSubmit: (values) => {
            const data = {
                id,
                status: 'Completed',
                admin: values.admin
            }
            dispatch(updateSchedule(data)).then(() => {
                toast.success("Schedule completed successfully", { position: "bottom-right" });
            })
            handleCompleteOpen();
        },
    });
    const handleOpen = () => {
        setOpen(!open);
    }
    const handleCompleteOpen = () => {
        setComplete(!complete);
    }
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Pick-up Schedules", path: "/dashboard/schedules" },
            { name: "Pick Up Details" }
        ])
    }, [])
    useEffect(() => {
        dispatch(getSingleSchedule(id));
        dispatch(getAllUsers({ role: "Admin" }))
        dispatch(getUserDetails());
        dispatch(getFridges());
    }, [dispatch, id])
    const unpasteurizedFridges = fridges ? fridges.filter((f) => f.fridgeType === 'Unpasteurized') : [];
    useEffect(() => {
        if (schedule && schedule.dates) {
            const date = new Date(schedule.dates)

            formik.setValues({
                newDate: new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16)
            })
        }
    }, [schedule])
    useEffect(() => {
        if (success) {
            dispatch(resetSuccess());
            navigate('/dashboard/schedules')
        }
    }, [dispatch, navigate, success])
    const submitFridge = () => {
        if (!selectedOption) {
            toast.error("Please select a fridge", { position: "bottom-right" });
            setOpenFridge(false);
            return;
        }
        console.log('selected option: ', selectedOption)
        const data = {
            fridgeId: selectedOption,
            unpasteurizedDetails: { collectionId },
            userId: userDetails._id
        }
        dispatch(addInventory(data)).then(() => {
            dispatch(recordPrivateRecord({ scheduleId: id, collectionId: collectionId, donorId: schedule.donorDetails.donorId._id }))
            toast.success("Collection stored successfully", { position: "bottom-right" });
            setOpenFridge(false);
        }).catch((error) => {
            toast.error("Failed to store collection. Please try again.", { position: "bottom-right" });
            console.error(error);
            setOpenFridge(false)
        })

    }
    let borderColorClass = 'border-green-600'; // default

    if (schedule?.status === 'Pending') {
        borderColorClass = 'border-yellow-400';
    } else if (schedule?.status === 'Approved') {
        borderColorClass = 'border-pink-600';
    }
    let actionContent = null;

    if (
        from === "RedirectDetails" &&
        status === "Collected" &&
        schedule?.status &&
        schedule.status !== "Approved"
    ) {
        actionContent = (
            <div className="w-full flex items-start justify-end gap-4">
                <Button color="green" onClick={handleOpenFridge}>Confirm</Button>
            </div>
        );
    } else if (from === "RedirectDetails" && status === "Stored") {
        actionContent = (
            <div className="w-full flex items-start justify-end gap-4">
                <Button disabled color="blue-gray">Stored</Button>
            </div>
        );
    } else if (schedule?.status === "Approved") {
        const isFuture = new Date(schedule.dates).setHours(0, 0, 0, 0) > new Date().setHours(0, 0, 0, 0);
        actionContent = (
            <div className="w-full flex items-start justify-end gap-4">
                <Button color="green" disabled={isFuture} onClick={handleCompleteOpen}>Complete</Button>
            </div>
        );
    } else if (schedule?.status === "Pending") {
        actionContent = (
            <div className="w-full flex items-start justify-end gap-4">
                <Button onClick={handleOpen} color="deep-orange">Change Date</Button>
                <Button color="pink" onClick={handleApprove}>Approve</Button>
            </div>
        );
    } else {
        actionContent = (
            <div className="w-full flex items-start justify-end gap-4">
                <Button disabled color="blue-gray">Picked Up</Button>
            </div>
        );
    }
    return (
        <div className="p-8">
            {from === "RedirectDetails" ? <Link to={`/dashboard/collections`}>
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link> : <Link to={`/dashboard/schedules`}>
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link>

            }

            <div className="flex flex-col gap-4 justify-between items-center">
                <div className="font-parkinsans text-2xl text-center">Pick Up Details</div>
                <Card className={`w-full border-l-8 ${borderColorClass}`}>
                    <CardBody>
                        <div className="flex flex-col gap-4">
                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Name of Donor</span>
                                <span className="font-parkinsans text-lg">{schedule && schedule.donorDetails && `${schedule.donorDetails.donorId.user.name.first} ${schedule.donorDetails.donorId.user.name.middle} ${schedule.donorDetails.donorId.user.name.last}`}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Express Date Range</span>
                                <span className="font-parkinsans text-lg">{schedule && new Date(schedule.oldestExpressDate).toLocaleString("en-US", {
                                    year: "numeric",
                                    month: "short",
                                    day: "numeric",
                                })} - {schedule && new Date(schedule.latestExpressDate).toLocaleString("en-US", {
                                    year: "numeric",
                                    month: "short",
                                    day: "numeric",
                                })}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Pick Up Date and Time</span>
                                <span className="font-parkinsans text-lg">{schedule && new Date(schedule.dates).toLocaleString("en-US", {
                                    year: "numeric",
                                    month: "long",
                                    day: "numeric",
                                    hour: "numeric",
                                    minute: "2-digit",
                                    hour12: true, // Ensures AM/PM format
                                })}</span>
                            </div>

                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Pick Up Address</span>
                                <span className="font-parkinsans text-lg">{schedule && schedule.address}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Contact Number</span>
                                <span className="font-parkinsans text-lg">{schedule && schedule.donorDetails && schedule.donorDetails.donorId && schedule.donorDetails.donorId.user.phone}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Pick Up Status</span>
                                <span className="font-parkinsans text-lg">{schedule && schedule.status}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="font-parkinsans text-lg">Total Volume</span>
                                <span className="font-parkinsans text-3xl text-secondary font-bold">{schedule && schedule.totalVolume} ml</span>
                            </div>
                        </div>
                    </CardBody>

                    <CardFooter>
                        {actionContent}

                        <Dialog size="sm" open={open} handler={handleOpen} className="p-4">
                            <form onSubmit={formik.handleSubmit}>
                                <div className="w-full">
                                    <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                        Pick Up Date and Time
                                    </Typography>
                                    <Input
                                        type="datetime-local"
                                        name="newDate"
                                        onChange={formik.handleChange}
                                        onBlur={formik.handleBlur}
                                        value={formik.values.newDate}
                                        error={formik.touched.newDate && Boolean(formik.errors.newDate)}
                                    />
                                    {formik.touched.newDate && formik.errors.newDate && (
                                        <Typography color="red" variant="small">
                                            {formik.errors.newDate}
                                        </Typography>
                                    )}
                                </div>
                                <div className="flex items-start justify-end pt-4">
                                    <Button type="submit" color="deep-orange">
                                        Update
                                    </Button>
                                </div>

                            </form>
                        </Dialog>
                        <Dialog size="sm" open={complete} handler={handleCompleteOpen} className="p-4">
                            <form onSubmit={formik2.handleSubmit}>
                                <div className="w-full">
                                    <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                        Choose Admin
                                    </Typography>
                                    <Select
                                        name="admin"
                                        onChange={(val) => formik2.setFieldValue("admin", val)}
                                        onBlur={formik2.handleBlur}
                                        value={formik2.values.admin}
                                        error={formik2.touched.admin && Boolean(formik2.errors.admin)}
                                    >

                                        {users && users.map((user) => (
                                            <Option key={user._id} value={user._id}>{user.name.first} {user.name.middle} {user.name.last}</Option>
                                        ))}

                                    </Select>
                                    {formik2.touched.admin && formik2.errors.admin && (
                                        <Typography color="red" variant="small">
                                            {formik2.errors.admin}
                                        </Typography>
                                    )}
                                </div>
                                <div className="flex items-start justify-end pt-4">
                                    <Button type="submit" color="deep-orange">
                                        Update
                                    </Button>
                                </div>

                            </form>
                        </Dialog>
                        <Dialog size="sm" open={openFridge} handler={handleOpenFridge} className="p-4">
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
                                    onClick={handleOpenFridge}
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
                                                id={fridge.name}
                                                name={fridge.name}
                                                value={fridge._id}
                                                className="peer hidden"
                                                required
                                                checked={selectedOption === fridge._id}
                                                onChange={handleChange}
                                            />
                                            <label
                                                htmlFor={fridge.name}
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
                    </CardFooter>
                </Card>
                <div className="font-parkinsans text-2xl text-center">Milk Bag Details</div>

                <div className="flex items-stretch gap-4 max-w-screen-2xl overflow-x-auto whitespace-nowrap">
                    {schedule?.donorDetails?.bags?.map((bag) => (
                        <div key={bag._id} className="min-w-max">
                            <BagDetails bag={bag} status={status} from={from} scheduleId={id} />
                        </div>
                    ))}
                </div>
            </div >

        </div>
    )
}

export default PickUpDetails