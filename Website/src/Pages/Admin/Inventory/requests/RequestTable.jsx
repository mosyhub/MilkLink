import React, { useState, useEffect } from 'react'
import { Button, Dialog, DialogBody, DialogFooter, DialogHeader, IconButton, Typography } from '@material-tailwind/react'
import { useDispatch } from 'react-redux'
import { Link } from 'react-router-dom'
import { XMarkIcon } from '@heroicons/react/24/solid'
import { EyeIcon, CheckCheck, Trash } from 'lucide-react'
import { formatDate, getUser } from '../../../../utils/helper'
import { deleteRequest, inpatientDispense, outpatientDispense } from '../../../../redux/actions/requestActions'
import { toast } from 'react-toastify'
import { createColumnHelper } from '@tanstack/react-table'
import DataTable from '../../../../Components/DataTables/tanstack/DataTable'
import PropTypes from 'prop-types'


function ActionsHeader({ reservedRequest, filteredRequest, dispenseInpatient }) {
    const shouldShowButton = reservedRequest.length > 0 && reservedRequest.length === filteredRequest.length;

    return (
        <th>
            {shouldShowButton ? (
                <Button color="green" onClick={dispenseInpatient}>
                    <CheckCheck className="h-5 w-5" />
                </Button>
            ) : (
                'View Details'
            )}
        </th>
    );
}
ActionsHeader.propTypes = {
    reservedRequest: PropTypes.array.isRequired,
    filteredRequest: PropTypes.array.isRequired,
    dispenseInpatient: PropTypes.func.isRequired,
}
function ActionsCell({ request, handleTransport, handleDelete }) {
    let actionContent;

    if (request.status === "Reserved" && request.patient.patientType === "Outpatient") {
        actionContent = (
            <Button className="bg-secondary" onClick={() => handleTransport(request)}>
                <CheckCheck className="h-5 w-5" />
            </Button>
        );
    } else if (request.status === "Canceled") {
        actionContent = (
            <div className="flex items-center gap-4">
                <Link to={`/dashboard/request/${request._id}`}>
                    <IconButton variant="text" className="text-secondary rounded-full">
                        <EyeIcon size={25} />
                    </IconButton>
                </Link>
                <IconButton
                    variant="text"
                    className="text-secondary rounded-full"
                    onClick={() => handleDelete(request._id)}
                >
                    <Trash size={22} className="text-secondary cursor-pointer" />
                </IconButton>
            </div>
        );
    } else {
        actionContent = (
            <Link to={`/dashboard/request/${request._id}`}>
                <IconButton variant="text" className="text-secondary rounded-full">
                    <EyeIcon size={25} />
                </IconButton>
            </Link>
        );
    }
    return (
        <div className="flex gap-2">
            {actionContent}
        </div>
    );
}
ActionsCell.propTypes = {
    request: PropTypes.object.isRequired,
    handleTransport: PropTypes.func.isRequired,
    handleDelete: PropTypes.func.isRequired,
}
const RequestTable = ({ requests, setRefresh }) => {
    const dispatch = useDispatch();
    const [items] = useState([
        { label: "Insulated Bag w/ Ice Pack", value: "Insulated Bag w/ Ice Pack" },
        { label: "Cooler w/ Ice Pack", value: "Cooler w/ Ice Pack" },
        { label: "Styro box w/ Ice Pack", value: "Styro box w/ Ice Pack" },
    ]);
    const [selectedOption, setSelectedOption] = useState(null);
    const [openTransport, setOpenTransport] = useState(false);
    const [formError, setFormError] = useState(() => ({
        transport: { status: false, message: "" }
    }));
    const [reservedRequest, setReservedRequest] = useState([]);
    const [filteredRequest, setFilteredRequest] = useState([]);
    const [id, setId] = useState(null);
    const handleTransport = (id) => {
        setOpenTransport(!openTransport);
        setId(id);
    }
    const handleChange = (e) => {
        setFormError((prev) => ({
            ...prev,
            transport: { status: false, message: "" }
        }))
        setSelectedOption(e.target.value);
    }
    const handleSubmit = () => {
        if (!selectedOption) {
            setFormError((prev) => ({
                ...prev,
                transport: { status: true, message: "Please select a transport type" }
            }))
            return;
        }
        if (id) {
            const data = {
                transport: selectedOption,
                request: id,
                approvedBy: getUser()._id,
                dispenseAt: Date.now()
            }
            console.log(data);

            dispatch(outpatientDispense(data)).then(() => {
                setOpenTransport(false);
                setId(null);
                setSelectedOption(null);
                toast.success("Request Dispensed successfully", { position: 'bottom-right' });
            })
        }
        else if (reservedRequest.length === filteredRequest.length) {

            const data = {
                transport: selectedOption,
                request: reservedRequest,
                dispenseAt: Date.now(),
                approvedBy: getUser()._id
            }
            dispatch(inpatientDispense(data)).then(() => {
                setOpenTransport(false);
                setId(null);
                setSelectedOption(null);
                setReservedRequest([]);
                setFilteredRequest([]);
                toast.success("Request Dispensed successfully", { position: 'bottom-right' });
            })
        }

    }

    const dispenseInpatient = () => {
        setOpenTransport(true);
        console.log(reservedRequest);
    }
    useEffect(() => {
        const filteredRequest = requests.filter(
            (req) =>
                req.patient &&
                req.patient.patientType === "Inpatient" &&
                req.status !== "Done" &&
                req.status !== "Canceled"
        );
        const reservedRequest = filteredRequest.filter(
            (req) => req.status === "Reserved" && req.tchmb.ebm.length > 0
        );
        setFilteredRequest(filteredRequest);
        setReservedRequest(reservedRequest);
    }, [requests])
    const handleDelete = (id) => {
        dispatch(deleteRequest(id)).then(() => {
            toast.success("Request deleted successfully", { position: 'bottom-right' });
            setRefresh(true);
        })
    }
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => formatDate(row.date), {
            id: 'date',
            header: 'Date',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.patient.name, {
            id: 'name',
            header: 'Patient Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.patient.patientType, {
            id: 'type',
            header: 'Patient Type',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.volumeRequested.volume, {
            id: 'volume',
            header: 'Requested Volume',
            cell: info => `${info.getValue()} ml`
        }),
        columnHelper.accessor(row => row.volumeRequested.days, {
            id: 'days',
            header: 'Days',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.doctor, {
            id: 'prescribedBy',
            header: 'Prescribed By',
            cell: info => info.getValue()
        }),
        columnHelper.accessor(row => row.status, {
            id: 'status',
            header: 'Status',
            cell: info => info.getValue()
        }),
        columnHelper.display({
            id: 'actions',
            header: () => (
                <ActionsHeader
                    reservedRequest={reservedRequest}
                    filteredRequest={filteredRequest}
                    dispenseInpatient={dispenseInpatient}
                />
            ),
            cell: ({ row }) => (
                <ActionsCell
                    request={row.original}
                    handleTransport={handleTransport}
                    handleDelete={handleDelete}
                />
            ),
        }),
    ];
    return (
        <div className="w-full h-full">

            <DataTable data={requests} columns={columns} pageSize={10} height="h-[calc(100vh-14rem)]"/>
            <Dialog size="sm" open={openTransport} handler={handleTransport} className="p-4">
                <DialogHeader className="relative m-0 block">
                    <Typography variant="h4" color="blue-gray">
                        Choose Transport Type
                    </Typography>
                    <Typography className="mt-1 font-normal text-gray-600">
                        Please select the transport type you would like to store the milk in.
                    </Typography>
                    <IconButton
                        size="sm"
                        variant="text"
                        className="!absolute right-3.5 top-3.5"
                        onClick={handleTransport}
                    >
                        <XMarkIcon className="h-4 w-4 stroke-2" />
                    </IconButton>
                </DialogHeader>
                <DialogBody>
                    <div className="space-y-4">

                        {items?.length > 0 && items.map((item) => (
                            <div key={item.value}>
                                <input
                                    type="radio"
                                    id={item.label}
                                    name={item.label}
                                    value={item.value}
                                    className="peer hidden"
                                    required
                                    checked={selectedOption === item.value}
                                    onChange={handleChange}
                                />
                                <label
                                    htmlFor={item.label}
                                    className="block w-full cursor-pointer rounded-lg border border-gray-300 p-4 text-gray-900 ring-1 ring-transparent peer-checked:border-gray-900 peer-checked:ring-gray-900"
                                >
                                    <div className="block">
                                        <Typography className="font-semibold">
                                            {item.label}
                                        </Typography>

                                    </div>
                                </label>
                            </div>
                        ))}
                        {formError?.transport?.status && <Typography color="red" variant="small">
                            {formError?.transport?.message}
                        </Typography>}
                    </div>
                    <DialogFooter>
                        <div className="flex items-start justify-end pt-4">
                            <Button color="green" onClick={handleSubmit}>
                                Confirm
                            </Button>
                        </div>
                    </DialogFooter>
                </DialogBody>
            </Dialog>

        </div>
    )
}

RequestTable.propTypes = {
    requests: PropTypes.array.isRequired,
    setRefresh: PropTypes.func.isRequired
}

export default RequestTable