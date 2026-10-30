import React, { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { getModelReport, getSubmissions, updateDonor } from '../../../redux/actions/donorActions';
import { Button, Card, CardBody, Dialog, DialogBody, DialogFooter, DialogHeader, IconButton, Typography } from '@material-tailwind/react';
import { EyeIcon, SquarePenIcon } from 'lucide-react';
import { formatDate, formatMetric } from '../../../utils/helper';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { toast } from 'react-toastify';
import { resetUpdate } from '../../../redux/slices/donorSlice';
import { createColumnHelper } from '@tanstack/react-table';
import DataTable from '../../../Components/DataTables/tanstack/DataTable';
import { Link } from 'react-router-dom';
import { ArrowLongLeftIcon } from '@heroicons/react/24/solid';
import Loader from '../../../Components/Loader/Loader';
import { useBreadcrumb } from '../../../Components/Breadcrumb/BreadcrumbContext';
import PropTypes from 'prop-types';

function ActionsCell({ row, handleOpen }) {
    const submissionID = row.original.submissionID;
    const _id = row.original._id;
    return (
        <div className="flex gap-2">
            <a target="_blank" href={`https://script.google.com/macros/s/AKfycbwYOc13QaEjdGoJvdlFEHZ2pSsIlUmx0zksazMKD3qfXYGnYG70eNSB7M5ZX0aOiU1y/exec?submissionId=${submissionID}`} rel="noreferrer">
                <IconButton variant="text" className="text-secondary rounded-full"><EyeIcon size={25} /></IconButton>
            </a>
            <IconButton variant="text" className="text-secondary rounded-full" onClick={() => handleOpen(_id)}><SquarePenIcon size={22} className="text-secondary" /></IconButton>

        </div>
    );
}
ActionsCell.propTypes = {
    row: PropTypes.object.isRequired,
    handleOpen: PropTypes.func.isRequired,
}
const Submissions = () => {
    const { setBreadcrumb } = useBreadcrumb();
    const dispatch = useDispatch();
    const { submissions, isUpdated, model, pythonLoading } = useSelector((state) => state.donors);
    useEffect(() => {
        setBreadcrumb([
            { name: "Dashboard", path: "/dashboard" },
            { name: "Interview Form Submissions", path: "/dashboard/submissions" }
        ])
    }, [])
    useEffect(() => {
        dispatch(getModelReport())
        dispatch(getSubmissions());
        if (isUpdated) {
            dispatch(resetUpdate())
        }
    }, [dispatch, isUpdated])
    const eligibilityOptions = ['Eligible', 'Ineligible'];
    const [open, setOpen] = useState(false);
    const [selectedOption, setSelectedOption] = useState('');
    const [id, setId] = useState('');
    const handleOpen = (id) => {
        setOpen(!open)
        setId(id);
    };
    const handleChange = (e) => {
        setSelectedOption(e.target.value)
    }
    const submit = () => {
        console.log("Selected option: ", selectedOption);
        console.log("ID: ", id);
        const data = {
            id: id,
            eligibility: selectedOption,
            verified: true
        }
        dispatch(updateDonor(data)).then(() => {
            toast.success("Eligibility updated successfully", { position: "bottom-right" });
            setOpen(!open);
        });

    }
    const columnHelper = createColumnHelper();

    const columns = [
        columnHelper.accessor(row => `${row.user.name.first} ${row.user.name.last}`, {
            id: 'name',
            header: 'Donor Name',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.eligibility, {
            id: 'eligibility',
            header: 'Prediction',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => `${formatDate(row.lastSubmissionDate)}`, {
            id: 'lastSubmissionDate',
            header: 'Submission Date',
            cell: info => info.getValue(),
        }),
        columnHelper.accessor(row => row.submissionID, {
            id: 'submissionID',
            header: 'Submission ID',
            cell: info => info.getValue()
        }),
        columnHelper.display({
            id: 'actions',
            header: 'Actions',
            cell: ({ row }) => (
                <ActionsCell row={row} handleOpen={handleOpen} />
            ),
        }),
    ];

    return (
        <div className="relative w-full h-full">
            <Link to="/dashboard" className="absolute top-4 left-4">
                <div className="mb-4 h-10 w-max bg-gray-200 rounded-lg p-4 flex justify-start items-center text-gray-700/50 hover:text-gray-700 transition-all hover:cursor-pointer">
                    <ArrowLongLeftIcon className="h-8 w-8" /> <span className="font-semibold text-md ml-2">Back</span>
                </div>
            </Link>
            <div className="h-[calc(30vh)] bg-secondary w-full p-4 mb-4">
                <Typography variant="h3" className="text-center mb-4 text-white font-parkinsans">Performance</Typography>
                <div className="flex items-stretch gap-4 w-full">
                    <Card className="flex-1">
                        <CardBody>
                            <Typography variant="h3" color="blue-gray" className="mb-2 font-parkinsans text-primary">
                                {pythonLoading ? <Loader /> : formatMetric(model?.accuracy)}
                            </Typography>
                            <Typography variant="h5" color="gray" className="mb-2">
                                Accuracy
                            </Typography>
                            <Typography>
                                How often the system is right overall.
                            </Typography>

                        </CardBody>
                    </Card>
                    <Card className="flex-1">
                        <CardBody>
                            <Typography variant="h3" color="blue-gray" className="mb-2 font-parkinsans text-primary">
                                {pythonLoading ? <Loader /> : formatMetric(model?.precision?.Overall, true)}
                            </Typography>
                            <Typography variant="h5" color="gray" className="mb-2">
                                Precision
                            </Typography>
                            <Typography>
                                How often those marked as eligible truly are.
                            </Typography>
                        </CardBody>
                    </Card>
                    <Card className="flex-1">
                        <CardBody>
                            <Typography variant="h3" color="blue-gray" className="mb-2 font-parkinsans text-primary">
                                {pythonLoading ? <Loader /> : formatMetric(model?.recall?.Overall, true)}
                            </Typography>
                            <Typography variant="h5" color="gray" className="mb-2">
                                Recall
                            </Typography>
                            <Typography>
                                How well the system finds all eligible donors.
                            </Typography>
                        </CardBody>
                    </Card>
                    <Card className="flex-1">
                        <CardBody>
                            <Typography variant="h3" color="blue-gray" className="mb-2 font-parkinsans text-primary">
                                {pythonLoading ? <Loader /> : formatMetric(model?.f1_score?.Overall, true)}
                            </Typography>
                            <Typography variant="h5" color="gray" className="mb-2">
                                F1 Score
                            </Typography>
                            <Typography>
                                A balance between precision and recall.
                            </Typography>
                        </CardBody>
                    </Card>
                </div>

            </div>
            <div className="p-4">
                <DataTable data={submissions} columns={columns} pageSize={10} height="h-[calc(70vh-8rem)]" />
            </div>

            <Dialog size="sm" open={open} handler={handleOpen} className="p-4">
                <DialogHeader className="relative m-0 block">
                    <Typography variant="h4" color="blue-gray">
                        Enter Eligibility
                    </Typography>
                    <Typography className="mt-1 font-normal text-gray-600">
                        Please select the eligibility status for the donor.
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
                    <div className="space-y-4">

                        {eligibilityOptions?.length > 0 && eligibilityOptions.map((type) => (
                            <div key={type}>
                                <input
                                    type="radio"
                                    id={type}
                                    name={type}
                                    value={type}
                                    className="peer hidden"
                                    required
                                    checked={selectedOption === type}
                                    onChange={handleChange}
                                />
                                <label
                                    htmlFor={type}
                                    className="block w-full cursor-pointer rounded-lg border border-gray-300 p-4 text-gray-900 ring-1 ring-transparent peer-checked:border-gray-900 peer-checked:ring-gray-900"
                                >
                                    <div className="block">
                                        <Typography className="font-semibold">
                                            {type}
                                        </Typography>

                                    </div>
                                </label>
                            </div>
                        ))}


                    </div>
                </DialogBody>
                <DialogFooter>
                    <Button className="ml-auto" onClick={submit}>
                        Select
                    </Button>
                </DialogFooter>
            </Dialog>

        </div>
    )
}

export default Submissions