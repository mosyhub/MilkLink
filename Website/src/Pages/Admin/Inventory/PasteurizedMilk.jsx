import React, { useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
    Button,
    Dialog,
    DialogBody,
    DialogFooter,
    DialogHeader,
    IconButton,
    Typography,
} from "@material-tailwind/react";
import { Link, useParams } from "react-router-dom";
import { ArrowLongLeftIcon, XMarkIcon } from "@heroicons/react/24/solid";
import { getFridges, openFridge } from "../../../redux/actions/fridgeActions";
import { EyeIcon } from 'lucide-react'
import { getUserDetails } from "../../../redux/actions/userActions";
import { formatDate } from "../../../utils/helper";
import { createColumnHelper } from "@tanstack/react-table";
import DataTable from "../../../Components/DataTables/tanstack/DataTable";
import { useBreadcrumb } from "../../../Components/Breadcrumb/BreadcrumbContext";
import PropTypes from "prop-types";

function AvailableVolume({ row }) {
    const availableVolume = row.original.pasteurizedDetails.bottles.map(b => b.status).filter(b => b === "Available").length * row.original.pasteurizedDetails.bottleType;
    return (
        <div className="flex gap-2">
            <p>{availableVolume} ml</p>
        </div>
    );
}
AvailableVolume.propTypes = {
    row: PropTypes.object.isRequired,
}
function ActionsCell({ row, handleOpen }) {

    return (
        <div className="bg-secondary w-max p-3 rounded-lg hover:cursor-pointer"
            onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault(); // Prevent page scroll on Space
                    handleOpen(row.original);
                }
            }}
            tabIndex={0}
            onClick={() => handleOpen(row.original)}>
            <EyeIcon className="h-5 w-5 text-white " />
        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
    handleOpen: PropTypes.func.isRequired,
}
const PasteurizedMilk = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const { id } = useParams()
    const dispatch = useDispatch()
    const [open, setOpen] = useState(0);
    const [inventory, setInventory] = useState({})

    const { fridgeContent } = useSelector(state => state.fridges)

    const handleOpen = (id) => {
        setInventory(id)
        setOpen(!open)
    };

    useEffect(() => {
        dispatch(openFridge(id));
        dispatch(getFridges())
        dispatch(getUserDetails());
    }, [dispatch])
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => formatDate(row.pasteurizedDetails.pasteurizationDate), {
            id: 'pasteurizationDate',
            header: 'Pasteurization Date',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.pasteurizedDetails.batch, {
            id: 'batch',
            header: 'Batch Number',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.pasteurizedDetails.pool, {
            id: 'pool',
            header: 'Pool Number',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.pasteurizedDetails.batchVolume, {
            id: 'volume',
            header: 'Batch Volume (ml)',
            cell: info => info.getValue()
        }),
        columnHelper.display({
            id: 'available',
            header: 'Available Volume (ml)',
            cell: ({ row }) => (
                <AvailableVolume row={row} />
            ),
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (
                <ActionsCell row={row} handleOpen={handleOpen} />
            ),
        }),
    ];
    const items = fridgeContent.filter((f) => f.status === "Available");
    useEffect(() => {
        setBreadcrumb([
            { name: 'Dashboard', path: '/dashboard' },
            { name: 'Refrigerator', path: '/dashboard/inventory/refrigerator' },
            { name: 'Pasteurized Milk' }
        ])
    }, [])
    return (
        <div className="w-full h-[calc(100vh-2rem)] overflow-y-scroll p-4" >
            <div className="flex justify-between items-center mb-4">
                <Link to={`/dashboard/inventory/refrigerator`}>
                    <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                        <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                    </div>
                </Link>

                <Dialog size="sm" open={open} handler={handleOpen} className="p-4">
                    <DialogHeader className="relative m-0 block">
                        <Typography variant="h4" color="blue-gray">
                            Pasteurization Details
                        </Typography>
                        <Typography className="mt-1 font-normal text-gray-800">
                            Date: {" "}
                            {inventory?.pasteurizedDetails?.pasteurizationDate ? formatDate(inventory?.pasteurizedDetails?.pasteurizationDate, "full") : ""}
                        </Typography>

                        <IconButton
                            size="sm"
                            variant="text"
                            className="!absolute right-3.5 top-3.5"
                            onClick={handleOpen}
                        >
                            <XMarkIcon className="h-4 w-4 stroke-2" />
                        </IconButton>
                    </DialogHeader>
                    <DialogBody>

                        <div className="grid grid-cols-2 place-items-baseline space-y-4">
                            <div className="w-full">
                                <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                    Batch number
                                </Typography>
                                <Typography className="mt-1 font-normal text-gray-600">
                                    {inventory?.pasteurizedDetails?.batch}
                                </Typography>
                            </div>
                            <div className="w-full">
                                <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                    Pool number
                                </Typography>
                                <Typography className="mt-1 font-normal text-gray-600">
                                    {inventory?.pasteurizedDetails?.pool}
                                </Typography>
                            </div>

                            <div className="w-full">
                                <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                    Available bottles
                                </Typography>
                                <Typography className="mt-1 font-normal text-gray-600">
                                    {inventory?.pasteurizedDetails?.bottles.map(b => b.status).filter(b => b === "Available").length}
                                </Typography>

                            </div>


                            <div className="w-full">
                                <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                    Batch Volume
                                </Typography>
                                <Typography className="mt-1 font-normal text-gray-600">
                                    {inventory?.pasteurizedDetails?.batchVolume} ml
                                </Typography>

                            </div>
                            <div className="w-full">
                                <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                    Bottle Type
                                </Typography>
                                <Typography className="mt-1 font-normal text-gray-600">
                                    {`${inventory?.pasteurizedDetails?.bottleType} ml`}
                                </Typography>
                            </div>
                            <div className="w-full">
                                <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                    Expiration Date
                                </Typography>
                                <Typography className="mt-1 font-normal text-gray-600">
                                    {inventory?.pasteurizedDetails?.expiration ? formatDate(inventory?.pasteurizedDetails?.expiration, "full") : ""}
                                </Typography>
                            </div>

                        </div>
                        <span className="flex items-center my-4">
                            <span className="h-px flex-1 bg-gray-500"></span>
                        </span>
                        <div className="space-y-4 mt-4">
                            <Typography variant="h5" color="blue-gray" className="mb-2 font-medium">
                                Donors
                            </Typography>
                            <div className="grid grid-cols-3 gap-4">
                                {inventory?.pasteurizedDetails?.donors.map((donor) => (
                                    <div key={donor._id} className="flex items-center justify-between bg-gray-100 p-4 rounded-lg shadow-md">
                                        <div className="flex items-center space-x-2">

                                            <Typography variant="h6" color="blue-gray" className="font-medium">{`${donor.user.name.first} ${donor.user.name.last}`}</Typography>
                                        </div>

                                    </div>
                                ))}
                            </div>
                        </div>
                    </DialogBody>
                    <DialogFooter>
                        <Button className="ml-auto" onClick={() => setOpen(!open)}>
                            Close
                        </Button>
                    </DialogFooter>
                </Dialog>

            </div>
            <DataTable data={items} columns={columns} pageSize={10} />



        </div >
    )
}

export default PasteurizedMilk