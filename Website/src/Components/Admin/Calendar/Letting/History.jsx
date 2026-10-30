import React, { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { getLettings } from '../../../../redux/actions/lettingActions'
import { Button, Card } from '@material-tailwind/react';
import { ArrowLongLeftIcon, EyeIcon } from '@heroicons/react/24/outline';
import { Link } from 'react-router-dom';
import {useBreadcrumb} from '../../../Breadcrumb/BreadcrumbContext'
const History = () => {
    const dispatch = useDispatch();
    const {setBreadcrumb} = useBreadcrumb();
    const { lettings, loading } = useSelector((state) => state.lettings);
    useEffect(()=>{
        setBreadcrumb([
            { name: 'Dashboard', path: '/dashboard' },
            { name: 'Event Schedules', path: '/dashboard/events' },
            { name: 'History'}
        ])
    },[])
    useEffect(() => {
        dispatch(getLettings());
    }, [dispatch])

    const filteredLettings = lettings.filter(
        (lets) => lets.status && lets.status === 'Done'
    );
    return (
        <div className='p-8'>
            <Link to={`/dashboard/events`}>
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link>
            <div className="text-2xl text-center">Event History</div>
            {loading ? <div>Loading...</div> : <div className="w-[calc(100wh-20rem)] h-[calc(100vh-20rem)] overflow-y-auto mx-auto flex flex-col items-center gap-4">

                {filteredLettings.length > 0 && filteredLettings.map((lets) => (
                    <Card key={lets._id} className='w-full border-l-8 border-secondary p-4 mx-auto mb-4 flex justify-between items-center flex-row'>
                        <div>
                            <div className="text-2xl font-bold text-secondary">{lets.activity}</div>
                            <div className="text-md">Venue: {lets.venue}</div>
                            <div className="text-md">Status: {lets.status}</div>
                            <div className="text-md">{` Date: ${new Date(lets.actDetails.date).toLocaleString("en-US", {
                                year: "numeric",
                                month: "long",
                                day: "numeric",
                            })}`}</div>
                            <div className="text-md">Donors: {lets.attendance.length}</div>
                            <div className="text-md">Total collected volume: {lets.totalVolume} ml</div>
                        </div>
                        <Link to={`/dashboard/events/attendance/${lets._id}`} state={{eventStatus: lets.status}}>
                            <Button className="bg-secondary"><EyeIcon className="h-5 w-5" /></Button>
                        </Link>
                    </Card>))}

            </div>}


        </div>
    )
}

export default History