import React, { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { getAllSchedules } from '../../../redux/actions/scheduleActions'

import { Typography } from '@material-tailwind/react'
import ScheduleComponent from '../../../Components/Admin/Calendar/Calendar'
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext'

const PickUpSchedule = () => {
    const dispatch = useDispatch();
    const {setBreadcrumb} = useBreadcrumb();
    const { schedules } = useSelector((state) => state.schedules);
    useEffect(()=>{
        setBreadcrumb([
            {name: "Dashboard", path: "/dashboard"},
            {name: "Pick-up Schedules"}
        ])
    },[])
    useEffect(() => {
        dispatch(getAllSchedules());
    }, [dispatch])

    useEffect(()=>{
        if (schedules) {
            console.log(schedules);
        }
    },[schedules])
    return (
        <div className="w-full p-4">
           

            {schedules && <ScheduleComponent events={schedules} type="pickup" />}
            <div className="flex items-center gap-4">
                <div className="flex items-center">
                    <div className="w-3 h-3 bg-[#FFC107] rounded-full"></div>
                    <Typography className="ml-2" variant="lead">Pending</Typography>
                </div>
                <div className="flex items-center">
                    <div className="w-3 h-3 bg-[#E53777] rounded-full"></div>
                    <Typography className="ml-2" variant="lead">Approved</Typography>
                </div>
                <div className="flex items-center">
                    <div className="w-3 h-3 bg-[#4CAF50] rounded-full"></div>
                    <Typography className="ml-2" variant="lead">Completed</Typography>
                </div>

            </div>
        </div>

    )
}

export default PickUpSchedule