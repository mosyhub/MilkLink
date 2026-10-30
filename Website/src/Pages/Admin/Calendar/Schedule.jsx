import React, { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'

import { Button, Typography } from '@material-tailwind/react'
import ScheduleComponent from '../../../Components/Admin/Calendar/Calendar'
import { AddEvent } from '../../../Components/Admin/Calendar/AddEvent'
import { getLettings } from '../../../redux/actions/lettingActions'
import { ClockIcon } from '@heroicons/react/24/outline'
import { Link } from 'react-router-dom'
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext'

const Schedule = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();

    const { lettings } = useSelector((state) => state.lettings);
    useEffect(() => {
        dispatch(getLettings());
    }, [dispatch])
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Event Schedules", path: "/dashboard/events" }
        ])
    }, [])


    return (
        <div className="w-full p-4">
            <div className="flex items-center justify-between gap-4 mb-4">
                <AddEvent />
                <Link to="/dashboard/event/history">
                    <Button size="sm" color="deep-orange" className="flex items-center justify-center gap-2">
                        <ClockIcon className="w-5 h-5" />
                        History
                    </Button>
                </Link>
            </div>

            {lettings && <ScheduleComponent events={lettings} type="events" />}
            <div className="flex items-center gap-4">

                <div className="flex items-center">
                    <div className="w-3 h-3 bg-neutral-dark rounded-full"></div>
                    <Typography className="ml-2" variant="lead">Upcoming</Typography>
                </div>
                <div className="flex items-center">
                    <div className="w-3 h-3 bg-secondary rounded-full"></div>
                    <Typography className="ml-2" variant="lead">On-Going</Typography>
                </div>
                <div className="flex items-center">
                    <div className="w-3 h-3 bg-success rounded-full"></div>
                    <Typography className="ml-2" variant="lead">Done</Typography>
                </div>

            </div>
        </div>

    )
}

export default Schedule