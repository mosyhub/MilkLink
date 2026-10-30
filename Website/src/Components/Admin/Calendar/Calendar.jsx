import React, { useState, useEffect } from 'react';
import { Calendar, momentLocalizer } from 'react-big-calendar';
import moment from 'moment';
import 'react-big-calendar/lib/css/react-big-calendar.css';
import { useNavigate } from 'react-router-dom';
const localizer = momentLocalizer(moment);
import { Dialog, DialogBody, DialogHeader, IconButton, Typography } from '@material-tailwind/react';
import { XMarkIcon } from '@heroicons/react/24/solid';
import PropTypes from 'prop-types';
// Custom agenda component
const CustomAgenda = ({ event }) => (
    <>
        <tr>
            <td>{event.title}<br></br>- {event.description} </td>
        </tr>
        {event.totalVolume &&
            <tr>
                <td>- Total Volume: {event.totalVolume} ml</td>
            </tr>}
        {event.bags &&
            <tr>
                <td>- Total Milk Bags: {event.bags.length} pcs.</td>
            </tr>
        }

    </>
);
CustomAgenda.propTypes = {
    event: PropTypes.shape({
        title: PropTypes.string.isRequired,
        description: PropTypes.string,
        totalVolume: PropTypes.number,
        bags: PropTypes.arrayOf(PropTypes.object),
    })
};

const ScheduleComponent = ({ events, type }) => {
    const navigate = useNavigate();

    const [items, setItems] = useState([]);
    const [open, setOpen] = useState(false);
    const [event, setEvent] = useState('');
    const handleOpen = async (event, type) => {

        if (event.status === "Done") {
            navigate(`/dashboard/events/attendance/${event.id}`, { state: { eventStatus: event.status } });
        }
        if (type === "events") {
            console.log("events: ", event);
            setEvent(event);
            setOpen(!open);

        }
        else if (type === "pickup") {
            navigate(`/dashboard/schedules/${event.id}`);
        }
    };
    useEffect(() => {
        if (type === "events") {
            const result = events.map((event) => { return { title: event.activity, description: event.description, start: new Date(event.actDetails.date), end: new Date(event.actDetails.date), id: event._id, status: event.status, venue: event.venue, attendance: event.attendance } });
            setItems(result);
        }
        else if (type === "pickup") {
            const result = events.map((event) => { return { start: new Date(event.dates), end: new Date(event.dates), title: `${event.donorDetails.donorId.user.name.first} ${event.donorDetails.donorId.user.name.middle} ${event.donorDetails.donorId.user.name.last}`, id: event._id, description: event.address, donorDetails: { name: `${event.donorDetails.donorId.user.name.first} ${event.donorDetails.donorId.user.name.middle.last} ${event.donorDetails.donorId.user.name.last}`, email: event.donorDetails.donorId.user.email, phone: event.donorDetails.donorId.user.phone }, totalVolume: event.totalVolume, status: event.status, bags: event.donorDetails.bags } });
            setItems(result);
        }

    }, [events, type])

    return (
        <div style={{ height: 500 }} className="mb-8">
            <Calendar
                localizer={localizer}
                events={items}
                startAccessor="start"
                endAccessor="end"
                views={['month', 'agenda']}
                defaultView="month"
                components={
                    {
                        agenda: {
                            event: CustomAgenda
                        }
                    }
                }
                onSelectEvent={event => { handleOpen(event, type) }}
                eventPropGetter={(event) => {
                    let backgroundColor = 'blue'; // Default color

                    // Ensure event has a status property
                    if (event.status) {
                        if (type === "events") {
                            if (event.status === 'Not-Due') backgroundColor = '#7A7A7A';
                            else if (event.status === 'On-Going') backgroundColor = '#E53777';
                            else if (event.status === 'Done') backgroundColor = '#4CAF50';
                        }
                        else if (type === "pickup") {
                            if (event.status === 'Pending') backgroundColor = '#FFC107';
                            else if (event.status === 'Approved') backgroundColor = '#E53777';
                            else if (event.status === 'Completed') backgroundColor = '#4CAF50';
                        }
                    }
                    return {
                        style: {
                            backgroundColor,
                            color: 'white', // Text color
                            borderRadius: '5px',
                            padding: '5px',
                        },
                    };
                }}
            />
            <Dialog size="sm" open={open} handler={() => handleOpen(events, type)} className="p-4">
                <Dialog size="sm" open={open} handler={handleOpen} className="p-4">
                    <DialogHeader className="relative m-0 block">
                        <Typography variant="h4" color="blue-gray">
                            Choose an action
                        </Typography>
                        <Typography className="mt-1 font-normal text-gray-600">
                            Please select your desired action for this event.
                        </Typography>
                        <IconButton
                            size="sm"
                            variant="text"
                            className="!absolute right-3.5 top-3.5"
                            onClick={() => handleOpen(events, type)}
                        >
                            <XMarkIcon className="h-4 w-4 stroke-2" />
                        </IconButton>
                    </DialogHeader>
                    <DialogBody>
                        <div className="space-y-4">
                            <div>
                                <input
                                    type="button"
                                    id="edit"
                                    name="edit"
                                    value="edit"
                                    className="peer hidden"
                                    required

                                    onClick={() => navigate(`/dashboard/events/${event.id}`)}
                                />
                                <label
                                    htmlFor="edit"
                                    className="block w-full cursor-pointer rounded-lg border border-gray-400 p-4 text-gray-900 hover:border-secondary-light hover:bg-secondary hover:text-white group"
                                >
                                    <div className="block">
                                        <Typography className="font-semibold">
                                            Edit Event
                                        </Typography>
                                        <Typography className="font-normal text-gray-600 group-hover:text-white">
                                            Edit the title, description, venue, dates, and status.

                                        </Typography>
                                    </div>
                                </label>
                            </div>

                            <div>
                                <input
                                    type="button"
                                    disabled={event && event.status !== "On-Going"}
                                    id="host"
                                    name="host"
                                    value="host"
                                    className="peer hidden"
                                    required

                                    onClick={() => navigate(`/dashboard/events/attendance/${event.id}`, { state: { from: "host" } })}
                                />
                                <label
                                    htmlFor="host"
                                    className={`block w-full rounded-lg border border-gray-400 p-4 text-gray-900 ${event && event.status === "On-Going" ? 'hover:cursor-pointer hover:border-secondary-light hover:bg-secondary hover:text-white group' : ''}`}
                                >
                                    <div className="block">
                                        <Typography className="font-semibold">
                                            Host Event {event && event.status !== "On-Going" && <span className=" text-sm text-neutral-dark">(Event must be On-Going)</span>}
                                        </Typography>
                                        <Typography className="font-normal text-gray-600 group-hover:text-white">
                                            List the attendance of donors and track their donated milk bags.
                                        </Typography>
                                    </div>
                                </label>
                            </div>

                        </div>
                    </DialogBody>

                </Dialog>
            </Dialog>
        </div>
    )
}
ScheduleComponent.propTypes = {
    events: PropTypes.array.isRequired,
    type: PropTypes.string.isRequired,
}

export default ScheduleComponent