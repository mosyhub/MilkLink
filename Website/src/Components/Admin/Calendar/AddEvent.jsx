import React, { useState, useEffect } from "react";
import {
    Input,
    Button,
    Textarea,
    IconButton,
    Typography,
    Drawer,
} from "@material-tailwind/react";
import DatePicker from 'react-datepicker';

import { XMarkIcon, PlusIcon } from "@heroicons/react/24/outline";
import { useFormik } from 'formik';
import * as Yup from 'yup';
import { useDispatch, useSelector } from 'react-redux'
import { getUser } from "../../../utils/helper";
import { resetSuccess } from "../../../redux/slices/eventSlice";
import { createLetting, getLettings } from "../../../redux/actions/lettingActions";
export function AddEvent() {
    const dispatch = useDispatch();
    const [open, setOpen] = useState(false);
    const { success } = useSelector(state => state.lettings);
    const handleOpen = () => setOpen(!open);
    const validationSchema = Yup.object({
        title: Yup.string().required("Title is required"),
        description: Yup.string(),
        venue: Yup.string().required("Venue is required"),
        

        date: Yup.date().required("Event date is required"),
        
    });

    const formik = useFormik({
        initialValues: {
            title: "",
            description: "",
            venue: "",
            status: "",
            date: "",
            

            user: getUser()._id
        },
        validationSchema,
        onSubmit: (values) => {
            const eventDate = new Date(values.date);
            
            const formData = {
                activity: values.title,
                venue: values.venue,
                actDetails: {
                    date: eventDate,
                },
                status: eventDate < new Date() ? "On-Going" : "Not-Due",
                description: values.description,
                admin: getUser()._id
            }
            console.log("formData", formData)
            dispatch(createLetting(formData));
            handleOpen();
        },
    });
    useEffect(() => {
        if (success) {
            formik.setValues({
                title: "",
                description: "",
                status: "",
                date: "",
                venue: "",
                user: getUser()._id
            })
            dispatch(resetSuccess());
            dispatch(getLettings());
        }
    }, [success])

    return (
        <>
            <Button onClick={handleOpen} className="flex items-center gap-2 bg-secondary" size="sm">
                <PlusIcon className="h-5 w-5" strokeWidth={2} /> Add Event
            </Button>
            <Drawer open={open} onClose={handleOpen} className="p-4" size={500}>
                <form onSubmit={formik.handleSubmit}>
                    <div className="overflow-y-auto h-[calc(100vh-5rem)] pr-2 space-y-4">
                        <div className="relative m-0 block">
                            <Typography variant="h4" color="blue-gray">
                                Add a new event
                            </Typography>
                            <Typography className="mt-1 font-normal text-gray-600">
                                Enter the details of the event.
                            </Typography>
                            <IconButton
                                size="sm"
                                variant="text"
                                className="!absolute right-3.5 top-3.5"
                                onClick={handleOpen}
                            >
                                <XMarkIcon className="h-4 w-4 stroke-2" />
                            </IconButton>
                        </div>
                        <div className="space-y-4 pb-6">
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
                           
                            <div className="flex flex-col gap-4 w-full">
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
                                            popperPlacement="bottom-start"
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
                        </div>
                    </div>
                    <div>
                        <Button type="submit" className="ml-auto">
                            Add Event
                        </Button>
                    </div>
                </form>
            </Drawer>
        </>
    );
}