import React, { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { useFormik } from 'formik';
import * as Yup from 'yup';
import { Card, CardHeader, CardBody, CardFooter, Typography, Input, Textarea, Button } from "@material-tailwind/react";
import { TrashIcon, ArrowLongLeftIcon } from "@heroicons/react/24/outline";
import { getUser } from "../../../utils/helper";
import { useParams, useNavigate, Link } from 'react-router-dom';
import { resetDelete, resetUpdate } from '../../../redux/slices/lettingSlice';
import { deleteLetting, getLettingDetails, updateLetting } from '../../../redux/actions/lettingActions';
import DatePicker from 'react-datepicker';
import { useBreadcrumb } from '../../Breadcrumb/BreadcrumbContext';
const EditEvent = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const navigate = useNavigate();
    const { id } = useParams();
    const dispatch = useDispatch();
    const { lettingDetails, isUpdated, isDeleted } = useSelector(state => state.lettings);
    const validationSchema = Yup.object({
        title: Yup.string().required("Title is required"),
        description: Yup.string(),
        venue: Yup.string(),
        status: Yup.string().required("Status is required"),

        date: Yup.date().required("Start date is required"),

    });

    const formik = useFormik({
        initialValues: {
            title: '',
            description: '',
            status: '',
            date: '',
            venue: '',

            user: getUser()._id
        },
        validationSchema,
        onSubmit: (values) => {
            const eventDate = new Date(values.date);

            const formData = {
                activity: values.title,
                venue: values.venue,
                date: eventDate,
                status: values.status,
                description: values.description,
                admin: getUser()._id,
                id
            }
            dispatch(updateLetting(formData));


        },
    });
    const handleDelete = () => {
        dispatch(deleteLetting(id));
    }
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Event Schedules", path: "/dashboard/events" },
            { name: "Edit Event", }
        ])
    }, [])
    useEffect(() => {
        const getDetails = async () => {
            await dispatch(getLettingDetails(id));
        };

        getDetails();
    }, [dispatch, id]); // Depend on `id` to fetch when it changes

    useEffect(() => {
        if (lettingDetails && lettingDetails.actDetails) {
            const eventDate = new Date(lettingDetails.actDetails.date)


            formik.setValues({
                title: lettingDetails.activity,
                description: lettingDetails.description,
                venue: lettingDetails.venue,
                status: lettingDetails.status,
                date: eventDate,
            });
        }
    }, [lettingDetails]); // Run when `eventDetails` updates

    useEffect(() => {
        if (isUpdated) {
            dispatch(resetUpdate());
            navigate('/dashboard/events');
        }
        if (isDeleted) {
            dispatch(resetDelete());
            navigate('/dashboard/events');
        }

    }, [isUpdated, isDeleted, navigate])
    return (
        <div className="p-8">
            <Link to="/dashboard/events">
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link>
            <Card className="w-full p-4 shadow-lg">
                {/* Card Header */}
                <CardHeader floated={false} shadow={false} className="relative mb-4 p-0">
                    <div className="flex gap-4 justify-between">
                        <Typography variant="h4" color="blue-gray">
                            Edit Event Details
                        </Typography>
                        <Button onClick={handleDelete} variant="filled" color="red" size="sm">
                            <TrashIcon className="h-5 w-5" />
                        </Button>
                    </div>

                    <Typography className="mt-1 font-normal text-gray-600">
                        Enter the updated details of the event.
                    </Typography>

                </CardHeader>

                {/* Card Body */}
                <form onSubmit={formik.handleSubmit}>
                    <CardBody className="space-y-4">
                        {/* Title */}
                        <div>
                            <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                Title
                            </Typography>
                            <Input
                                name="title"
                                placeholder="e.g. Breastfeeding Awareness Month"
                                onChange={formik.handleChange}
                                onBlur={formik.handleBlur}
                                value={formik.values.title}
                                error={formik.touched.title && Boolean(formik.errors.title)}
                            />
                            {formik.touched.title && formik.errors.title && (
                                <Typography color="red" variant="small">
                                    {formik.errors.title}
                                </Typography>
                            )}
                        </div>
                        <div>
                            <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                Venue
                            </Typography>
                            <Input
                                name="venue"
                                placeholder="e.g. Taguig City"
                                onChange={formik.handleChange}
                                onBlur={formik.handleBlur}
                                value={formik.values.venue}
                                error={formik.touched.venue && Boolean(formik.errors.venue)}
                            />
                            {formik.touched.venue && formik.errors.venue && (
                                <Typography color="red" variant="small">
                                    {formik.errors.venue}
                                </Typography>
                            )}
                        </div>
                        {/* Description */}
                        <div>
                            <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                Description (Optional)
                            </Typography>
                            <Textarea
                                name="description"
                                placeholder="e.g. Hold a seminar on the importance of breastfeeding."
                                onChange={formik.handleChange}
                                onBlur={formik.handleBlur}
                                value={formik.values.description}
                            />
                        </div>

                        {/* Date Fields */}
                        <div className="flex gap-4">
                            {/* Start Date */}
                            <div className="w-full">
                                <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                                    Event Date
                                </Typography>
                                <div className="add-event w-full">
                                    <DatePicker
                                        selected={formik.values.date}
                                        onChange={(date) => formik.setFieldValue("date", date)}
                                        onBlur={formik.handleBlur}
                                        onCalendarClose={() => console.log("Calendar closed")} // Optional hook
                                        dateFormat="MMMM d, yyyy h:mm aa"
                                        showTimeSelect
                                        className={`w-full p-2 border ${formik.touched.date && formik.errors.date
                                            ? "border-red-500"
                                            : "border-gray-400"
                                            } rounded-lg focus:outline-none focus:ring-2 focus:ring-primary`}
                                        placeholderText="Select a date and time"
                                        shouldCloseOnSelect={true}
                                        popperPlacement="top-start"
                                        timeIntervals={10}
                                    />
                                </div>
                                {formik.touched.date && formik.errors.date && (
                                    <Typography color="red" variant="small">
                                        {formik.errors.date}
                                    </Typography>
                                )}
                            </div>


                        </div>
                    </CardBody>

                    {/* Card Footer */}
                    <CardFooter className="pt-4 flex justify-end gap-4">
                        <Button type="submit" color="pink">
                            Update
                        </Button>
                    </CardFooter>
                </form>
            </Card>
        </div>
    )
}

export default EditEvent