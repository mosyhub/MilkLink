import React, { useState, useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import {
    Button,
    Card,
    Typography,
    Input,
    Drawer,
    Menu,
    MenuHandler,
    MenuList,
    MenuItem,
    IconButton
} from "@material-tailwind/react";
import { toast } from 'react-toastify';
import { deleteAttendance, updateAttendance } from '../../../../redux/actions/lettingActions';
import { createColumnHelper } from '@tanstack/react-table';
import DataTable from '../../../DataTables/tanstack/DataTable';
import { formatDate } from '../../../../utils/helper';
import DatePicker from 'react-datepicker';
import { EllipsisVertical, Trash2 } from 'lucide-react';
import { resetSuccess } from '../../../../redux/slices/lettingSlice';
import PropTypes from 'prop-types';

function ActionsCell({ row, from, lettingId, handleOpen, handleDelete, status }) {
    const attendees = row.original;
    const attendanceId = row.original._id;
    const name = `${attendees.donor.user.name.first} ${attendees.donor.user.name.middle} ${attendees.donor.user.name.last}`;

    let isDisabled = true;
    if (from === "RedirectDetails") {
        if (status === "Stored") isDisabled = true;
    } else if (from === "host") {
        isDisabled = false;
    }

    return (
        <div className="flex justify-center items-center gap-2">
            <Menu>
                <MenuHandler>
                    <IconButton disabled={isDisabled} className="rounded-full" variant="text">
                        <EllipsisVertical size={20} />
                    </IconButton>
                </MenuHandler>
                <MenuList>
                    <MenuItem onClick={() => handleOpen(attendees.donor._id, name)}>Add bags</MenuItem>
                    {from !== "RedirectDetails" && (
                        <MenuItem onClick={() => handleDelete(attendanceId, lettingId)}>Delete</MenuItem>
                    )}
                </MenuList>
            </Menu>
        </div>
    );
}

ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
    from: PropTypes.string.isRequired,
    lettingId: PropTypes.string.isRequired,
    handleOpen: PropTypes.func.isRequired,
    handleDelete: PropTypes.func.isRequired,
    status: PropTypes.string.isRequired
}
const AttendanceTable = ({ setRefresh, attendance, status, from, lettingId }) => {
    const dispatch = useDispatch();
    const { success } = useSelector((state) => state.lettings);
    const [open, setOpen] = useState(false);
    const [id, setId] = useState('');
    const [name, setName] = useState('');
    const [bags, setBags] = useState([]);
    const [bagDetails, setBagDetails] = useState(() => ({
        volume: "",
        expressDate: null
    }))

    const handleDelete = (attendanceId, lettingId) => {
        dispatch(deleteAttendance({ lettingId, attendanceId })).then(() => {
            toast.success("Successfully deleted")
        })
    }

    const handleOpen = (id, name) => {
        setId(id);
        setName(name);
        setOpen((cur) => !cur)
    };
    const getTotalVolume = (bags) => {
        return bags.reduce((acc, bag) => acc + bag.volume, 0)
    }

    const resetStates = () => {
        setBagDetails({
            volume: "",
            expressDate: "",
        });
        setBags([]);

    }

    const submitUpdate = () => {
        if (bags.length === 0) {
            toast.error("No bags added.")
            return;
        }
        const data = {
            lettingId,
            donorId: id,
            bags
        }
        dispatch(updateAttendance(data))
            .then(() => {

                toast.success("Attendance updated", { position: "bottom-right" });
            })
            .catch((error) => {
                toast.error("Failed to update attendance", { position: "bottom-right" });
                console.error(error);
            });
        resetStates();
        setOpen(false);
    }
    const handleVolumeChange = (e) => {
        setBagDetails({
            ...bagDetails,
            volume: e.target.value
        })
    }

    const addBag = () => {
        const { volume, expressDate } = bagDetails;

        if (!volume || !expressDate) {
            toast.error("Please fill out volume and express date", { position: "bottom-right" })
            return;
        }
        if (isNaN(volume)) {
            toast.error("Volume must be a number")
            return;
        }

        const newBags = {
            volume: Number(volume),
            expressDate: expressDate,
        };

        setBags([...bags, newBags]);
        setBagDetails({
            ...bagDetails,
            volume: "",
            expressDate: "",
        });
    }
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.display({
            id: 'index',
            header: 'No.',
            cell: ({ row }) => row.index + 1, // starts from 1 instead of 0
        }),
        columnHelper.accessor(row => `${row.donor.user.name.first} ${row.donor.user.name.last}`, {
            id: 'name',
            header: 'Name',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.lastDonation ? `${formatDate(row.lastDonation)}` : 'New Donor', {
            id: 'lastDonation',
            header: 'Last Breast Milk Donation / New Donor',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => getTotalVolume(row.bags), {
            id: 'expressedMilk',
            header: 'Expressed Breast Milk',
            cell: info => `${info.getValue()} ml`
        }),
        columnHelper.accessor(row => row.additionalBags ? getTotalVolume(row.additionalBags) : 0, {
            id: 'additionalBags',
            header: 'Additional bags',
            cell: info => `${info.getValue()} ml`
        }),
        columnHelper.accessor(row => `${row.donor.home_address.street}, ${row.donor.home_address.brgy}, ${row.donor.home_address.city}`, {
            id: 'address',
            header: 'Address',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.donor.user.phone, {
            id: 'phone',
            header: 'Phone',
            cell: info => info.getValue()
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (
                <ActionsCell
                    row={row}
                    from={from}
                    lettingId={lettingId}
                    handleOpen={handleOpen}
                    handleDelete={handleDelete}
                    status={status}
                />
            ),
        }),
    ];
    useEffect(() => {

        if (success) {
            setRefresh(true)
            dispatch(resetSuccess());
        }
    }, [success])
    return (
        <div className="w-full h-full">
            <DataTable data={attendance} columns={columns} pageSize={10} />
            <Drawer open={open} onClose={handleOpen} size={500} className="p-4">
                <div className="overflow-y-auto h-[calc(100vh-5rem)] pr-2 space-y-4">
                    <Typography variant="h4" color="blue-gray">
                        Add more bags
                    </Typography>
                    <Typography
                        className="mb-3 font-normal"
                        variant="paragraph"
                        color="gray"
                    >
                        Donor: {name}
                    </Typography>
                    <div className="w-full">
                        <Typography variant="small" color="blue-gray" className="mb-2 font-medium">
                            Express date
                        </Typography>
                        <div className="add-event w-full">
                            <DatePicker
                                selected={bagDetails.expressDate}
                                onChange={(date) => { setBagDetails({ ...bagDetails, expressDate: date }) }}
                                onCalendarClose={() => console.log("Calendar closed")} // Optional hook
                                dateFormat="MMMM d, yyyy h:mm aa"
                                showTimeSelect
                                className={`w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary`}
                                placeholderText="Select a date and time"
                                shouldCloseOnSelect={true}
                                popperPlacement="left-end"
                                timeIntervals={10}
                            />
                        </div>

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
                    <Card className="h-96 w-full overflow-y-scroll">
                        <table className="w-full min-w-max table-auto text-left">
                            <thead>
                                <th className="border-b border-blue-gray-100 bg-secondary-light p-4">
                                    <Typography variant="small" color="white" className="font-normal leading-none opacity-70">
                                        No.
                                    </Typography>
                                </th>
                                <th className="border-b border-blue-gray-100 bg-secondary-light p-4">
                                    <Typography variant="small" color="white" className="font-normal leading-none opacity-70">
                                        Volume
                                    </Typography>
                                </th>
                                <th className="border-b border-blue-gray-100 bg-secondary-light p-4">
                                    <Typography variant="small" color="white" className="font-normal leading-none opacity-70">
                                        Date
                                    </Typography>
                                </th>
                                <th className="border-b border-blue-gray-100 bg-secondary-light p-4">
                                    <Typography variant="small" color="white" className="font-normal leading-none opacity-70">
                                        Action
                                    </Typography>
                                </th>
                            </thead>
                            <tbody>
                                {bags.length > 0 && bags.map((bag, index) => (
                                    <tr key={bag._id} >
                                        <td className="p-4 border-b border-blue-gray-50">
                                            <Typography variant="small" color="blue-gray" className="font-normal">
                                                {index + 1}
                                            </Typography>
                                        </td>
                                        <td className="p-4 border-b border-blue-gray-50">
                                            <Typography variant="small" color="blue-gray" className="font-normal">
                                                {bag.volume} ml
                                            </Typography>
                                        </td>
                                        <td className="p-4 border-b border-blue-gray-50">
                                            <Typography variant="small" color="blue-gray" className="font-normal">
                                                {new Date(bag.expressDate).toLocaleString("en-US", {
                                                    weekday: "short",
                                                    year: "numeric",
                                                    month: "short",
                                                    day: "numeric",
                                                    hour: "numeric",
                                                    minute: "numeric",
                                                })}
                                            </Typography>

                                        </td>
                                        <td className="p-4 border-b border-blue-gray-50">
                                            <Trash2 className="h-5 w-5 text-red-500 hover:cursor-pointer" onClick={() => setBags(bags.filter((_, i) => i !== index))} />
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>

                    </Card>
                </div>
                <div className="flex items-center justify-between gap-4">
                    <Button variant="gradient" color="green" onClick={addBag} fullWidth>
                        Add bags
                    </Button>
                    <Button variant="gradient" color="pink" onClick={submitUpdate} fullWidth>
                        Update
                    </Button>
                </div>

            </Drawer >
        </div >
    )
}
AttendanceTable.propTypes = {
    setRefresh: PropTypes.func.isRequired,
    attendance: PropTypes.array.isRequired,
    status: PropTypes.string.isRequired,
    from: PropTypes.string.isRequired,
    lettingId: PropTypes.string.isRequired
}
export default AttendanceTable